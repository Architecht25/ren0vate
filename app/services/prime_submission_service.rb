class PrimeSubmissionService
  attr_reader :property, :user, :params, :result

  def initialize(property, user, params)
    @property = property
    @user = user
    @params = params
    @result = OpenStruct.new(success?: false, error: nil, dossier_number: nil)
  end

  def call
    return failure("Utilisateur non autorisé") unless user.can_submit?
    return failure("Propriété non prête") unless property.ready_for_submission?

    begin
      # 1. Créer le dossier de soumission
      submission = create_submission_record

      # 2. Générer le PDF du formulaire
      pdf_path = generate_form_pdf(submission)

      # 3. Soumettre vers l'administration (selon la région)
      admin_response = submit_to_administration(submission, pdf_path)

      # 4. Enregistrer la réponse
      update_submission_status(submission, admin_response)

      # 5. Créer la notification pour l'utilisateur
      create_notification(submission)

      success(submission.dossier_number)
    rescue StandardError => e
      Rails.logger.error "Erreur soumission: #{e.message}"
      failure("Erreur technique lors de la soumission")
    end
  end

  private

  def create_submission_record
    PrimeSubmission.create!(
      property: property,
      user: user,
      region: property.region,
      dossier_number: generate_dossier_number,
      status: 'submitted',
      form_data: build_submission_data,
      submitted_at: Time.current
    )
  end

  def generate_dossier_number
    "REN#{property.region.upcase}#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(4).upcase}"
  end

  def build_submission_data
    {
      demandeur: {
        nom: user.last_name,
        prenom: user.first_name,
        email: user.email,
        telephone: user.phone
      },
      logement: {
        adresse: "#{property.numero} #{property.rue}",
        code_postal: property.code_postal,
        commune: property.commune,
        type: property.type,
        ean: property.numero_ean
      },
      travaux: extract_travaux_data,
      documents: extract_documents_data
    }
  end

  def extract_travaux_data
    # À adapter selon vos données de travaux
    {
      toiture: property.has_travaux?('toiture'),
      murs: property.has_travaux?('murs'),
      vitrage: property.has_travaux?('vitrage'),
      sol: property.has_travaux?('sol'),
      chauffage: property.has_travaux?('chauffage')
    }
  end

  def extract_documents_data
    property.documents.approved.group_by(&:type_document).transform_values(&:count)
  end

  def generate_form_pdf(submission)
    # Générer le PDF du formulaire pré-rempli
    FormulairePdfService.new(submission).generate
  end

  def submit_to_administration(submission, pdf_path)
    case property.region
    when 'flandre'
      FlandreSubmissionService.new(submission, pdf_path).submit
    when 'wallonie'
      WallonieSubmissionService.new(submission, pdf_path).submit
    when 'bruxelles'
      BruxellesSubmissionService.new(submission, pdf_path).submit
    else
      raise "Région non supportée: #{property.region}"
    end
  end

  def update_submission_status(submission, admin_response)
    submission.update!(
      admin_reference: admin_response[:reference],
      admin_status: admin_response[:status],
      admin_response_data: admin_response[:data]
    )
  end

  def create_notification(submission)
    Notification.create!(
      user: user,
      property: property,
      title: "Demande de prime soumise",
      message: "Votre demande a été soumise avec succès. Numéro de dossier: #{submission.dossier_number}",
      notification_type: 'submission_success'
    )
  end

  def success(dossier_number)
    @result.success = true
    @result.dossier_number = dossier_number
    @result
  end

  def failure(error_message)
    @result.error = error_message
    @result
  end
end
