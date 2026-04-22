require 'prawn'
require 'prawn/table'

class PdfReportService
  BRAND_BLUE  = '1a56b0'.freeze
  BRAND_LIGHT = 'e8f0fe'.freeze
  GRAY        = '6c757d'.freeze
  BLACK       = '212529'.freeze

  def initialize(project, user)
    @project = project
    @user    = user
    @factures = project.factures.where(type_facture: %w[facture acompte solde etat_avancement]).order(:date_facture)
    @devis    = project.devis_donnees.order(:date_devis)
    @sims     = project.simulations.order(created_at: :desc).first(3)
  end

  def generate
    Prawn::Document.new(
      page_size:    'A4',
      margin:       [40, 50, 40, 50],
      info: {
        Title:    "Rapport — #{@project.nom}",
        Author:   "Ren0vate",
        Creator:  "Ren0vate Platform",
        CreationDate: Time.current
      }
    ) do |pdf|
      @pdf = pdf
      add_header
      add_project_info
      add_factures_section
      add_devis_section
      add_simulations_section
      add_footer
    end.render
  end

  private

  def add_header
    @pdf.bounding_box([0, @pdf.cursor], width: @pdf.bounds.width, height: 70) do
      @pdf.fill_color BRAND_BLUE
      @pdf.fill_rectangle [@pdf.bounds.left, @pdf.cursor], @pdf.bounds.width, 70
      @pdf.fill_color 'ffffff'
      @pdf.text_box "Ren0vate",
                    at: [10, @pdf.cursor - 12],
                    size: 20, style: :bold
      @pdf.text_box "Rapport de projet",
                    at: [10, @pdf.cursor - 36],
                    size: 12
      @pdf.text_box Date.current.strftime('%d/%m/%Y'),
                    at: [@pdf.bounds.width - 100, @pdf.cursor - 24],
                    size: 10, align: :right, width: 90
    end
    @pdf.move_down 80
    @pdf.fill_color BLACK
  end

  def add_project_info
    section_title("Informations du projet")

    rows = [
      ["Nom du projet", @project.nom],
      ["Type", @project.type_display.to_s],
      ["Statut", @project.statut&.humanize || 'En cours'],
      ["Bien", @project.property&.full_address.to_s],
      ["Date début", @project.date_début&.strftime('%d/%m/%Y').to_s],
      ["Date fin prévue", @project.date_fin&.strftime('%d/%m/%Y').to_s]
    ].reject { |_, v| v.blank? }

    table_data = rows.map { |k, v| [{ content: k, font_style: :bold, background_color: BRAND_LIGHT }, v] }

    @pdf.table(table_data, width: @pdf.bounds.width, cell_style: { border_color: 'dddddd', padding: [5, 8] }) do
      column(0).width = 180
    end
    @pdf.move_down 20
  end

  def add_factures_section
    section_title("Factures (#{@factures.count})")

    if @factures.any?
      headers = [
        { content: 'Date',         background_color: BRAND_BLUE, text_color: 'ffffff' },
        { content: 'Numéro',       background_color: BRAND_BLUE, text_color: 'ffffff' },
        { content: 'Type',         background_color: BRAND_BLUE, text_color: 'ffffff' },
        { content: 'Entreprise',   background_color: BRAND_BLUE, text_color: 'ffffff' },
        { content: 'HT (€)',       background_color: BRAND_BLUE, text_color: 'ffffff', align: :right },
        { content: 'TTC (€)',      background_color: BRAND_BLUE, text_color: 'ffffff', align: :right },
        { content: 'Statut',       background_color: BRAND_BLUE, text_color: 'ffffff' }
      ]

      rows = @factures.map do |f|
        [
          f.date_facture&.strftime('%d/%m/%Y').to_s,
          f.numero_facture.to_s,
          f.type_facture&.humanize.to_s,
          truncate_str(f.nom_entreprise, 20),
          format_eur(f.montant_ht),
          format_eur(f.montant),
          f.statut_paiement&.humanize.to_s
        ]
      end

      total_ht  = @factures.sum(:montant_ht).to_f
      total_ttc = @factures.sum(:montant).to_f
      rows << [
        { content: 'TOTAL', font_style: :bold, colspan: 4, align: :right, background_color: BRAND_LIGHT },
        { content: format_eur(total_ht),  font_style: :bold, align: :right, background_color: BRAND_LIGHT },
        { content: format_eur(total_ttc), font_style: :bold, align: :right, background_color: BRAND_LIGHT },
        { content: '', background_color: BRAND_LIGHT }
      ]

      @pdf.table([headers] + rows, width: @pdf.bounds.width, header: true,
                 cell_style: { border_color: 'dddddd', padding: [4, 6], size: 9 }) do
        column(4).align = :right
        column(5).align = :right
      end
    else
      @pdf.text "Aucune facture enregistrée.", color: GRAY, style: :italic
    end
    @pdf.move_down 20
  end

  def add_devis_section
    section_title("Devis scannés (#{@devis.count})")

    if @devis.any?
      headers = [
        { content: 'Date',       background_color: BRAND_BLUE, text_color: 'ffffff' },
        { content: 'Numéro',     background_color: BRAND_BLUE, text_color: 'ffffff' },
        { content: 'Entreprise', background_color: BRAND_BLUE, text_color: 'ffffff' },
        { content: 'HTVA (€)',   background_color: BRAND_BLUE, text_color: 'ffffff', align: :right },
        { content: 'TVAC (€)',   background_color: BRAND_BLUE, text_color: 'ffffff', align: :right }
      ]

      rows = @devis.map do |d|
        [
          d.date_devis&.strftime('%d/%m/%Y').to_s,
          d.numero_devis.to_s,
          truncate_str(d.nom_entreprise, 28),
          format_eur(d.montant_total_htva),
          format_eur(d.montant_total_tvac)
        ]
      end

      @pdf.table([headers] + rows, width: @pdf.bounds.width, header: true,
                 cell_style: { border_color: 'dddddd', padding: [4, 6], size: 9 })
    else
      @pdf.text "Aucun devis scanné.", color: GRAY, style: :italic
    end
    @pdf.move_down 20
  end

  def add_simulations_section
    return if @sims.empty?
    section_title("Simulations de primes (#{@sims.count} dernières)")

    rows = @sims.map do |s|
      [
        s.created_at&.strftime('%d/%m/%Y').to_s,
        s.region.to_s,
        format_eur(s.total_simule)
      ]
    end

    headers = [
      { content: 'Date',    background_color: BRAND_BLUE, text_color: 'ffffff' },
      { content: 'Région',  background_color: BRAND_BLUE, text_color: 'ffffff' },
      { content: 'Primes potentielles (€)', background_color: BRAND_BLUE, text_color: 'ffffff', align: :right }
    ]

    @pdf.table([headers] + rows, width: @pdf.bounds.width, header: true,
               cell_style: { border_color: 'dddddd', padding: [4, 6], size: 9 })
    @pdf.move_down 20
  end

  def add_footer
    @pdf.repeat :all do
      @pdf.bounding_box([0, @pdf.bounds.bottom + 20], width: @pdf.bounds.width, height: 20) do
        @pdf.fill_color GRAY
        @pdf.text "Ren0vate — rapport généré le #{Date.current.strftime('%d/%m/%Y')} — Confidentiel",
                  size: 8, align: :center
        @pdf.fill_color BLACK
      end
    end
  end

  def section_title(title)
    @pdf.fill_color BRAND_BLUE
    @pdf.fill_rounded_rectangle [@pdf.bounds.left, @pdf.cursor], @pdf.bounds.width, 22, 3
    @pdf.fill_color 'ffffff'
    @pdf.text_box title, at: [@pdf.bounds.left + 8, @pdf.cursor - 5], size: 11, style: :bold
    @pdf.fill_color BLACK
    @pdf.move_down 28
  end

  def format_eur(value)
    return '—' if value.nil?
    "#{'%.2f' % value.to_f} €"
  end

  def truncate_str(str, len)
    return '—' if str.blank?
    str.length > len ? "#{str[0...len]}…" : str
  end
end
