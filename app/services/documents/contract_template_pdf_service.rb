module Documents
  # Génère un PDF pour un template de contrat (contract_templates#preview / #download) via Prawn.
  Prawn::Fonts::AFM.hide_m17n_warning = true

  class ContractTemplatePdfService
    NAVY  = "1e3a5f"
    MUTED = "6c757d"
    GREEN = "198754"

    def initialize(template)
      @template = template
    end

    def generate
      Prawn::Document.new(
        page_size:   "A4",
        page_layout: :portrait,
        margin:      [30, 35, 30, 35],
        info: {
          Title:   @template[:title],
          Author:  "Ren0vate",
          Creator: "Ren0vate",
          Subject: "Template de contrat"
        }
      ) do |pdf|
        setup_fonts(pdf)
        header(pdf)
        parties(pdf)
        sections(pdf)
        legal_compliance(pdf)
        disclaimer(pdf)
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
      pdf.fill_color NAVY
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 52
      pdf.fill_color "ffffff"
      pdf.bounding_box([10, pdf.cursor - 8], width: pdf.bounds.width - 20, height: 44) do
        pdf.text @template[:title].to_s, size: 15, style: :bold
        pdf.text "#{@template[:category]}  ·  Généré le #{Date.today.strftime('%d/%m/%Y')}", size: 8, color: "ccddee"
      end
      pdf.move_down 60
      pdf.fill_color "000000"

      if @template[:description].present?
        pdf.text @template[:description].to_s, size: 9, color: MUTED
        pdf.move_down 12
      end
    end

    def parties(pdf)
      parties = @template.dig(:content, :parties)
      return if parties.blank?

      section_title(pdf, "Parties")
      parties.each do |key, value|
        pdf.text "#{key.to_s.humanize} : #{value}", size: 9
      end
      pdf.move_down 14
    end

    def sections(pdf)
      sections = @template.dig(:content, :sections)
      return if sections.blank?

      section_title(pdf, "Contenu du contrat")
      sections.each do |key, text|
        pdf.text key.to_s.humanize, size: 10, style: :bold, color: NAVY
        pdf.move_down 2
        pdf.text text.to_s, size: 9, leading: 2
        pdf.move_down 10
      end
    end

    def legal_compliance(pdf)
      laws = @template[:legal_compliance]
      return if laws.blank?

      section_title(pdf, "Conformité légale")
      laws.each do |law|
        pdf.fill_color GREEN
        pdf.text "• #{law}", size: 9
      end
      pdf.fill_color "000000"
      pdf.move_down 14
    end

    def disclaimer(pdf)
      pdf.move_down 6
      pdf.fill_color "f8f9fa"
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 44
      pdf.fill_color MUTED
      pdf.bounding_box([8, pdf.cursor - 6], width: pdf.bounds.width - 16, height: 36) do
        pdf.text "Ce modèle est fourni à titre indicatif. Il est recommandé de le faire vérifier et adapter " \
                  "par un juriste spécialisé en fonction de votre situation avant signature.", size: 8, leading: 2
      end
      pdf.fill_color "000000"
    end

    def section_title(pdf, label)
      pdf.text label, size: 11, style: :bold, color: NAVY
      pdf.move_down 6
    end

    def footer(pdf)
      pdf.repeat(:all) do
        pdf.bounding_box([0, pdf.bounds.absolute_bottom + 18],
                         width: pdf.bounds.width, height: 14) do
          pdf.fill_color MUTED
          pdf.font_size 6 do
            pdf.text "Ren0vate · Template de contrat · #{@template[:title]}", align: :center
          end
        end
      end
    end
  end
end
