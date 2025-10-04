class ComplementRequest < ApplicationRecord
  belongs_to :request_progress

  # Relation vers request via request_progress
  delegate :request, to: :request_progress

  # Documents complémentaires
  has_many_attached :complement_documents
  has_many_attached :response_documents

  validates :admin_message, presence: true
  validates :deadline, presence: true
  validates :status, presence: true

  # Enum pour les statuts
  enum :status, {
    pending: 'pending',           # En attente de réponse du client
    in_progress: 'in_progress',   # Client en cours de préparation
    completed: 'completed',       # Complément fourni
    expired: 'expired',          # Délai dépassé
    rejected: 'rejected'         # Complément refusé par l'admin
  }

  # Enum pour les types de complément
  enum :complement_type, {
    missing_documents: 'missing_documents',
    technical_clarification: 'technical_clarification',
    additional_info: 'additional_info',
    document_quality: 'document_quality',
    eligibility_verification: 'eligibility_verification'
  }

  # Callbacks
  before_create :set_default_deadline
  after_create :notify_client
  after_update :handle_status_change

  # Scopes
  scope :active, -> { where(status: ['pending', 'in_progress']) }
  scope :overdue, -> { where('deadline < ? AND status IN (?)', Date.current, ['pending', 'in_progress']) }

  # Méthodes
  def expired?
    deadline < Date.current && !completed?
  end

  def days_remaining
    return 0 if expired?
    (deadline - Date.current).to_i
  end

  def mark_in_progress!
    update!(status: 'in_progress', started_at: Time.current)
  end

  def submit_response!(response_message = nil)
    update!(
      status: 'completed',
      client_response: response_message,
      completed_at: Time.current
    )

    # Relancer le traitement de la demande
    request_progress.process_complement_response!
  end

  def mark_expired!
    update!(status: 'expired', expired_at: Time.current)
    request_progress.handle_complement_expiry!
  end

  def approve_response!
    update!(status: 'completed', approved_at: Time.current)
    request_progress.resume_processing!
  end

  def reject_response!(rejection_reason)
    update!(
      status: 'rejected',
      rejection_reason: rejection_reason,
      rejected_at: Time.current
    )
  end

  # Analyse du complément
  def analyze_response
    analysis = {
      documents_provided: response_documents.count,
      response_length: client_response&.length || 0,
      submitted_on_time: !expired?,
      days_taken: completed_at ? (completed_at.to_date - created_at.to_date).to_i : nil
    }

    analysis[:completeness_score] = calculate_completeness_score
    analysis[:quality_indicators] = assess_quality_indicators

    analysis
  end

  def generate_summary
    {
      request_id: request_progress.request.id,
      complement_type: complement_type,
      requested_at: created_at,
      deadline: deadline,
      status: status,
      response_time: response_time_analysis,
      documents: document_summary,
      next_actions: suggest_next_actions
    }
  end

  private

  def set_default_deadline
    # Délai par défaut selon le type de complément
    days_to_add = case complement_type
    when 'missing_documents' then 15
    when 'technical_clarification' then 10
    when 'document_quality' then 7
    else 14
    end

    self.deadline = days_to_add.days.from_now.to_date
  end

  def notify_client
    ComplementRequestMailer.new_request(self).deliver_later
  end

  def handle_status_change
    return unless status_changed?

    case status
    when 'completed'
      ComplementRequestMailer.response_received(self).deliver_later
    when 'expired'
      ComplementRequestMailer.deadline_expired(self).deliver_later
    when 'rejected'
      ComplementRequestMailer.response_rejected(self).deliver_later
    end
  end

  def calculate_completeness_score
    # Score basé sur les documents fournis et la qualité de la réponse
    score = 0

    # Points pour les documents
    score += 40 if response_documents.any?
    score += 20 if response_documents.count >= required_documents_count

    # Points pour la réponse textuelle
    if client_response.present?
      score += 20
      score += 20 if client_response.length > 100
    end

    score
  end

  def assess_quality_indicators
    indicators = []

    indicators << 'response_complete' if client_response.present? && client_response.length > 50
    indicators << 'documents_provided' if response_documents.any?
    indicators << 'on_time_submission' unless expired?
    indicators << 'proactive_communication' if status == 'in_progress'

    indicators
  end

  def required_documents_count
    # Nombre de documents attendus selon le type de complément
    case complement_type
    when 'missing_documents' then 3
    when 'document_quality' then 2
    else 1
    end
  end

  def response_time_analysis
    return nil unless completed_at

    {
      days_taken: (completed_at.to_date - created_at.to_date).to_i,
      percentage_of_deadline: ((completed_at.to_date - created_at.to_date).to_f / (deadline - created_at.to_date).to_f * 100).round,
      speed_category: categorize_response_speed
    }
  end

  def categorize_response_speed
    return 'unknown' unless completed_at

    days_taken = (completed_at.to_date - created_at.to_date).to_i
    total_days_allowed = (deadline - created_at.to_date).to_i
    percentage = (days_taken.to_f / total_days_allowed * 100)

    case percentage
    when 0..25 then 'very_fast'
    when 26..50 then 'fast'
    when 51..75 then 'normal'
    when 76..100 then 'slow'
    else 'overdue'
    end
  end

  def document_summary
    {
      requested_count: required_documents_count,
      provided_count: response_documents.count,
      document_types: response_documents.map { |doc| doc.content_type }.uniq,
      total_size: response_documents.sum(&:byte_size)
    }
  end

  def suggest_next_actions
    actions = []

    case status
    when 'completed'
      actions << 'review_response'
      actions << 'validate_documents' if response_documents.any?
      actions << 'resume_processing'
    when 'pending'
      if days_remaining <= 3
        actions << 'send_reminder'
      end
    when 'expired'
      actions << 'contact_client'
      actions << 'extend_deadline'
      actions << 'close_request'
    end

    actions
  end
end
