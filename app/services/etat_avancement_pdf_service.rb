# frozen_string_literal: true
#
# Génère un PDF de bordereau de paiement pour un EtatAvancement via Prawn.
#
Prawn::Fonts::AFM.hide_m17n_warning = true

class EtatAvancementPdfService
  include ActionView::Helpers::NumberHelper

  NAVY   = "1e3a5f"
  ACCENT = "d97706"
  LIGHT  = "f8f9fa"
  MUTED  = "6c757d"
  GREEN  = "198754"
  RED    = "dc3545"

  def initialize(etat)
    @etat    = etat
    @project = etat.project
    @lignes  = etat.lignes.order(:position)
  end

  def generate
    Prawn::Document.new(
      page_size:    "A4",
      page_layout:  :portrait,
      margin:       [30, 35, 30, 35],
      info: {
        Title:    "État d'avancement n°#{@etat.numero} — #{@project.nom}",
        Author:   "Ren0vate",
        Creator:  "Ren0vate",
        Subject:  "Bordereau de paiement",
        Keywords: "bordereau avancement chantier renovation"
      }
    ) do |pdf|
      setup_fonts(pdf)
      header(pdf)
      project_info(pdf)
      kpi_row(pdf)
      ia_resume(pdf) if @etat.resume_ia.present?
      thematiques(pdf)
      signature_block(pdf)
      footer(pdf)
    end
  end

  private

  def setup_fonts(pdf)
    pdf.font_families.update(
      "Helvetica" => {
        normal:      { file: "Helvetica" },
        bold:        { file: "Helvetica-Bold" },
        italic:      { file: "Helvetica-Oblique" },
        bold_italic: { file: "Helvetica-BoldOblique" }
      }
    )
    pdf.font "Helvetica"
  end

  def header(pdf)
    # Bande titre
    pdf.fill_color NAVY
    pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 52
    pdf.fill_color "ffffff"
    pdf.bounding_box([10, pdf.cursor - 8], width: pdf.bounds.width - 20, height: 44) do
      pdf.text "ÉTAT D'AVANCEMENT N°#{@etat.numero}", size: 16, style: :bold
      statut_text = @etat.statut_label.upcase
      pdf.text "#{statut_text}  ·  #{@etat.source_label}  ·  #{Date.today.strftime('%d/%m/%Y')}",
               size: 8, color: "ccddee"
    end
    pdf.move_down 60
    pdf.fill_color "000000"
  end

  def project_info(pdf)
    property = @project.property rescue nil
    address  = property ? property.full_address : ""

    pdf.fill_color LIGHT.gsub("#", "")
    pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 38
    pdf.fill_color "000000"

    pdf.bounding_box([8, pdf.cursor - 6], width: pdf.bounds.width - 16, height: 30) do
      pdf.text @project.nom.to_s, size: 10, style: :bold
      pdf.text address, size: 8, color: MUTED if address.present?
      parts = []
      parts << "Entrepreneur : #{@project.entrepreneur_principal_entreprise}" if @project.entrepreneur_principal_entreprise.present?
      parts << "Architecte : #{@project.architecte_entreprise || [@project.architecte_prenom, @project.architecte_nom].compact.join(' ')}" if @project.architecte_nom.present?
      pdf.text parts.join("   ·   "), size: 7, color: MUTED if parts.any?
    end
    pdf.move_down 42
  end

  def kpi_row(pdf)
    col_w = pdf.bounds.width / 4.0
    [
      ["Avancement global", "#{@etat.avancement_global_pct} %", NAVY],
      ["Réclamé (période)",  fmt_money(@etat.montant_reclame_periode), ACCENT],
      ["Cumul actuel",       fmt_money(@etat.montant_cumule_actuel), GREEN],
      ["Total marché",       fmt_money(@etat.montant_total_marche), MUTED]
    ].each_with_index do |(label, value, color), i|
      x = i * col_w
      pdf.fill_color "f0f4f8"
      pdf.fill_rectangle [x + 2, pdf.cursor], col_w - 4, 32
      pdf.fill_color color
      pdf.draw_text value, at: [x + 6, pdf.cursor - 16], size: 12, style: :bold
      pdf.fill_color MUTED
      pdf.draw_text label, at: [x + 6, pdf.cursor - 26], size: 7
    end
    pdf.fill_color "000000"
    pdf.move_down 38
  end

  def ia_resume(pdf)
    return unless @etat.resume_ia.present?
    pdf.fill_color "f0eeff"
    pdf.fill_rounded_rectangle [0, pdf.cursor], pdf.bounds.width, 30, 3
    pdf.fill_color "4f46e5"
    pdf.draw_text "IA", at: [6, pdf.cursor - 18], size: 7, style: :bold
    pdf.fill_color "333333"
    pdf.bounding_box([20, pdf.cursor - 6], width: pdf.bounds.width - 26, height: 22) do
      pdf.text @etat.resume_ia.to_s.truncate(220), size: 7, leading: 2
    end
    pdf.fill_color "000000"
    pdf.move_down 36
  end

  def thematiques(pdf)
    @etat.lignes_par_thematique.each do |_code, lignes|
      next if lignes.empty?
      theme = lignes.first
      montant_theme = lignes.sum { |l| l.montant_marche.to_f }
      reclame_theme = lignes.sum { |l| l.montant_reclame.to_f }

      # En-tête thématique
      pdf.fill_color NAVY
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 16
      pdf.fill_color "ffffff"
      pdf.draw_text theme.thematique_label.to_s, at: [6, pdf.cursor - 11], size: 9, style: :bold
      pdf.draw_text "#{lignes.count} postes  ·  #{fmt_money(montant_theme)} €  ·  réclamé : #{fmt_money(reclame_theme)} €",
                    at: [pdf.bounds.width - 200, pdf.cursor - 11], size: 7
      pdf.fill_color "000000"
      pdf.move_down 20

      # Tableau lignes
      col_widths = [45, 0, 60, 55, 40, 55]
      col_widths[1] = pdf.bounds.width - col_widths.sum  # désignation prend le reste

      table_data = [["Réf.", "Désignation", "Qté/Unit.", "Marché", "% act.", "Réclamé"]]
      lignes.each do |l|
        table_data << [
          l.reference.to_s.truncate(8),
          [l.designation.to_s.truncate(60), l.sous_secteur.present? ? "(#{l.sous_secteur})" : nil].compact.join("\n"),
          l.quantite.present? ? "#{l.quantite} #{l.unite}" : (l.unite.to_s),
          fmt_money(l.montant_marche) + " €",
          "#{l.pct_cumule_actuel}%",
          fmt_money(l.montant_reclame) + " €"
        ]
      end

      begin
        pdf.table(table_data,
          column_widths: col_widths,
          row_colors:    ["ffffff", "f8f9fa"],
          header:        true,
          cell_style:    { size: 7, padding: [3, 4], border_width: 0, border_color: "e9ecef" }
        ) do |t|
          t.row(0).background_color = "e8edf2"
          t.row(0).font_style = :bold
          t.row(0).text_color = NAVY
          t.columns(3..5).align = :right
        end
      rescue StandardError => e
        pdf.text "Erreur rendu tableau : #{e.message}", size: 7, color: "cc0000"
      end

      pdf.move_down 10
      break if pdf.cursor < 80  # évite débordement page
    end
  end

  def signature_block(pdf)
    pdf.move_down 20
    pdf.stroke_color "dddddd"
    pdf.stroke_horizontal_rule
    pdf.move_down 12
    pdf.fill_color MUTED
    pdf.text "Signatures", size: 8, style: :bold
    pdf.move_down 8

    col = pdf.bounds.width / 3.0
    [
      ["Entrepreneur", @project.entrepreneur_principal_entreprise || ""],
      ["Architecte",   [@project.architecte_prenom, @project.architecte_nom].compact.join(" ")],
      ["Maître d'ouvrage", @project.user.full_name]
    ].each_with_index do |(role, name), i|
      x = i * col
      pdf.fill_color "000000"
      pdf.draw_text role, at: [x + 4, pdf.cursor], size: 7, style: :bold
      pdf.fill_color MUTED
      pdf.draw_text name.truncate(28), at: [x + 4, pdf.cursor - 10], size: 7
      pdf.fill_color "cccccc"
      pdf.stroke_color "cccccc"
      pdf.stroke { pdf.line [x + 4, pdf.cursor - 24], [x + col - 8, pdf.cursor - 24] }
      pdf.fill_color MUTED
      pdf.draw_text "Date & Signature :", at: [x + 4, pdf.cursor - 34], size: 6
    end
    pdf.fill_color "000000"
  end

  def footer(pdf)
    pdf.repeat(:all) do
      pdf.bounding_box([0, pdf.bounds.absolute_bottom + 18],
                       width: pdf.bounds.width, height: 14) do
        pdf.fill_color MUTED
        pdf.font_size 6 do
          pdf.text "Ren0vate · Bordereau n°#{@etat.numero} · #{@project.nom} · Généré le #{Date.today.strftime('%d/%m/%Y')}",
                   align: :center
        end
      end
    end
  end

  def fmt_money(amount)
    return "0,00" if amount.nil?
    format("%.2f", amount.to_f).gsub(".", ",")
  end
end
