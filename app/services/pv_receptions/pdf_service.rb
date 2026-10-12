module PvReceptions
  # Génère un PDF du PV de réception via Prawn (même pattern que
  # Devis::EtatAvancementPdfService) — utilisé par VaultsController pour
  # inclure le PV dans l'export ZIP du coffre-fort quand il a été généré dans
  # l'app (source != "externe", donc pas de pv_externe_file attaché). Pour un
  # PV externe (scanné), VaultsController joint directement pv_externe_file.
  Prawn::Fonts::AFM.hide_m17n_warning = true

  class PdfService
    NAVY  = "1e3a5f"
    MUTED = "6c757d"
    GREEN = "198754"
    RED   = "dc3545"

    def initialize(pv)
      @pv = pv
      @project = pv.project
    end

    def generate
      Prawn::Document.new(
        page_size: "A4",
        page_layout: :portrait,
        margin: [30, 35, 30, 35],
        info: {
          Title: "PV de réception — #{@project.nom}",
          Author: "Ren0vate",
          Creator: "Ren0vate",
          Subject: "Procès-verbal de réception de chantier"
        }
      ) do |pdf|
        header(pdf)
        project_info(pdf)
        presence_info(pdf)
        reserves(pdf)
        observations(pdf)
        signatures(pdf)
        footer(pdf)
      end
    end

    private

    def header(pdf)
      pdf.fill_color NAVY
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 52
      pdf.fill_color "ffffff"
      pdf.bounding_box([10, pdf.cursor - 8], width: pdf.bounds.width - 20, height: 44) do
        pdf.text "PV DE RÉCEPTION DE CHANTIER", size: 16, style: :bold
        date_text = @pv.date_reception&.strftime("%d/%m/%Y") || "Date non renseignée"
        pdf.text "#{@pv.statut_label}  ·  #{date_text}", size: 8, color: "ccddee"
      end
      pdf.move_down 60
      pdf.fill_color "000000"
    end

    def project_info(pdf)
      property = @project.property
      address = property&.full_address

      pdf.fill_color "f8f9fa"
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 38
      pdf.fill_color "000000"
      pdf.bounding_box([8, pdf.cursor - 6], width: pdf.bounds.width - 16, height: 30) do
        pdf.text @project.nom.to_s, size: 10, style: :bold
        pdf.text address, size: 8, color: MUTED if address.present?
        pdf.text "Météo : #{@pv.meteo}", size: 7, color: MUTED if @pv.meteo.present?
      end
      pdf.move_down 42
    end

    def presence_info(pdf)
      pdf.text "Présents", size: 9, style: :bold, color: NAVY
      pdf.text @pv.presents.presence || "—", size: 8
      pdf.move_down 6
      if @pv.absents.present?
        pdf.text "Absents", size: 9, style: :bold, color: NAVY
        pdf.text @pv.absents, size: 8
        pdf.move_down 6
      end
      if @pv.coordinateur_sps.present?
        pdf.text "Coordinateur SPS : #{@pv.coordinateur_sps}", size: 8, color: MUTED
        pdf.move_down 6
      end
      pdf.move_down 8
    end

    def reserves(pdf)
      liste = @pv.reserves_liste
      pdf.text "Réserves (#{liste.size})", size: 9, style: :bold, color: NAVY
      pdf.move_down 4

      if liste.empty?
        pdf.text "Aucune réserve constatée à la réception.", size: 8, color: MUTED
      else
        table_data = [["Description", "Statut", "Responsable", "Échéance"]]
        liste.each do |r|
          table_data << [
            r["description"].to_s.truncate(70),
            r["statut"].to_s,
            r["responsable"].to_s,
            r["date_limite"].to_s
          ]
        end

        begin
          pdf.table(table_data,
            width: pdf.bounds.width,
            header: true,
            cell_style: { size: 7, padding: [3, 4], border_width: 0.5, border_color: "e9ecef" }
          ) do |t|
            t.row(0).background_color = "e8edf2"
            t.row(0).font_style = :bold
            t.row(0).text_color = NAVY
          end
        rescue StandardError => e
          pdf.text "Erreur rendu tableau réserves : #{e.message}", size: 7, color: RED
        end
      end
      pdf.move_down 16
    end

    def observations(pdf)
      return if @pv.observations.blank?
      pdf.text "Observations", size: 9, style: :bold, color: NAVY
      pdf.move_down 4
      pdf.text @pv.observations, size: 8
      pdf.move_down 16
    end

    def signatures(pdf)
      pdf.stroke_color "dddddd"
      pdf.stroke_horizontal_rule
      pdf.move_down 12
      pdf.text "Signatures", size: 8, style: :bold, color: MUTED
      pdf.move_down 8

      rows = [
        ["Maître d'ouvrage", @pv.nom_owner, @pv.signed_owner?],
        ["Architecte", @pv.nom_architect, @pv.signed_architect?],
        ["Entrepreneur", @pv.nom_entrepreneur, @pv.signed_entrepreneur?]
      ].select { |_, name, _| name.present? }

      col = pdf.bounds.width / [rows.size, 1].max
      rows.each_with_index do |(role, name, signed), i|
        x = i * col
        pdf.fill_color "000000"
        pdf.draw_text role, at: [x + 4, pdf.cursor], size: 7, style: :bold
        pdf.fill_color MUTED
        pdf.draw_text name.to_s.truncate(28), at: [x + 4, pdf.cursor - 10], size: 7
        pdf.fill_color signed ? GREEN : "cccccc"
        pdf.draw_text signed ? "Signé" : "En attente de signature", at: [x + 4, pdf.cursor - 20], size: 6
      end
      pdf.fill_color "000000"
    end

    def footer(pdf)
      pdf.repeat(:all) do
        pdf.bounding_box([0, pdf.bounds.absolute_bottom + 18], width: pdf.bounds.width, height: 14) do
          pdf.fill_color MUTED
          pdf.font_size 6 do
            pdf.text "Ren0vate · PV de réception · #{@project.nom} · Généré le #{Date.today.strftime('%d/%m/%Y')}", align: :center
          end
        end
      end
    end
  end
end
