class ChantierVisionJob < ApplicationJob
  queue_as :default

  def perform(project_id)
    project = Project.find(project_id)

    Rails.logger.info "🔍 ChantierVisionJob — début analyse photos projet ##{project_id}"

    result = ChantierVisionService.new(project).call

    if result[:success]
      now = Time.current

      # 1. Mettre à jour le résultat courant sur le projet (affichage widget)
      project.update!(
        vision_analysis:    result.slice(:avancement, :phase, :observations, :alertes, :prochaines_etapes),
        vision_analysed_at: now
      )

      # 2. Créer un enregistrement d'historique
      analysis = project.chantier_analyses.create!(
        avancement:        result[:avancement],
        phase:             result[:phase],
        observations:      Array(result[:observations]).join("\n"),
        alertes:           Array(result[:alertes]).join("\n"),
        prochaines_etapes: Array(result[:prochaines_etapes]).join("\n"),
        photos_count:      result[:analysed_count].to_i,
        analysed_at:       now
      )

      # 3. Créer un Document etat_avancement lié au projet
      rapport_notes = build_rapport_notes(result, now)
      doc = project.user.documents.build(
        type_document: 'etat_avancement',
        status:        'approved',
        property:      project.property,
        project:       project,
        notes:         rapport_notes
      )
      doc.save!

      Rails.logger.info "✅ ChantierVisionJob — analyse OK projet ##{project_id} — avancement #{result[:avancement]}% — analyse ##{analysis.id}"
    else
      Rails.logger.warn "⚠️ ChantierVisionJob — échec projet ##{project_id} : #{result[:error]}"
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "❌ ChantierVisionJob — projet ##{project_id} introuvable"
  rescue => e
    Rails.logger.error "❌ ChantierVisionJob error: #{e.message}"
    raise
  end

  private

  def build_rapport_notes(result, analysed_at)
    lines = []
    lines << "📊 Analyse IA chantier — #{analysed_at.strftime('%d/%m/%Y à %H:%M')}"
    lines << "Avancement estimé : #{result[:avancement]}%"
    lines << "Phase : #{result[:phase]}"
    lines << ""
    if Array(result[:alertes]).any?
      lines << "⚠️ ALERTES"
      Array(result[:alertes]).each { |a| lines << "• #{a}" }
      lines << ""
    end
    if Array(result[:observations]).any?
      lines << "OBSERVATIONS"
      Array(result[:observations]).each { |o| lines << "• #{o}" }
      lines << ""
    end
    if Array(result[:prochaines_etapes]).any?
      lines << "PROCHAINES ÉTAPES"
      Array(result[:prochaines_etapes]).each { |e| lines << "• #{e}" }
    end
    lines.join("\n")
  end
end
