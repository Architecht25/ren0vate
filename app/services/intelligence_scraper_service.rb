class IntelligenceScraperService
  include HTTParty

  # Sources RSS belges pertinentes pour Ren0vate
  # Clé = identifiant, url = flux RSS, label = nom affiché dans le rapport
  SOURCES = [
    {
      key: 'spw_energie',
      label: 'SPW Énergie (Wallonie)',
      url: 'https://energie.wallonie.be/fr/rss.xml?IDC=19026',
      region: 'Wallonie'
    },
    {
      key: 'bruxelles_env',
      label: 'Bruxelles Environnement',
      url: 'https://www.bruxellesenvironnement.be/rss/actualites.xml',
      region: 'Bruxelles'
    },
    {
      key: 'fednot',
      label: 'Fednot (actualités notariales)',
      url: 'https://www.notaire.be/rss/fr/news.xml',
      region: 'Belgique'
    },
    {
      key: 'vlaanderen_energie',
      label: 'VEKA / Énergie Flandre',
      url: 'https://www.vlaanderen.be/api/news/rss?entity=ondersteuning-voor-renovatie',
      region: 'Flandre'
    },
    {
      key: 'statbel_immo',
      label: 'Statbel — Statistiques immobilier',
      url: 'https://statbel.fgov.be/fr/rss/news',
      region: 'Belgique'
    }
  ].freeze

  MAX_ITEMS_PER_SOURCE = 5
  REQUEST_TIMEOUT      = 15

  def initialize
    @results = []
  end

  # Retourne { sources: [...], total_items: N, formatted_text: "..." }
  def fetch_all
    SOURCES.each do |source|
      items = fetch_source(source)
      @results << { source: source[:label], region: source[:region], items: items }
    rescue => e
      Rails.logger.warn "IntelligenceScraperService — échec #{source[:key]}: #{e.message}"
      @results << { source: source[:label], region: source[:region], items: [], error: e.message }
    end

    {
      sources:        @results,
      total_items:    @results.sum { |r| r[:items].length },
      formatted_text: build_text
    }
  end

  private

  def fetch_source(source)
    response = HTTParty.get(
      source[:url],
      timeout: REQUEST_TIMEOUT,
      headers: { 'User-Agent' => 'Ren0vate-IntelligenceBot/1.0' },
      follow_redirects: true
    )

    return [] unless response.success?

    parse_rss(response.body)
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn "IntelligenceScraperService — timeout #{source[:url]}"
    []
  end

  def parse_rss(xml_body)
    doc = Nokogiri::XML(xml_body)
    items = doc.css('item, entry')  # RSS 2.0 = <item>, Atom = <entry>

    items.first(MAX_ITEMS_PER_SOURCE).map do |item|
      title       = item.at_css('title')&.text&.strip
      description = item.at_css('description, summary, content')&.text&.strip
      pub_date    = item.at_css('pubDate, published, updated')&.text&.strip
      link        = item.at_css('link')&.text&.strip || item.at_css('link')&.attr('href')

      # Nettoyer le HTML éventuel dans la description
      description = Nokogiri::HTML(description).text.strip if description&.include?('<')
      description = description&.truncate(300)

      { title: title, description: description, date: pub_date, url: link }.compact
    end.reject { |i| i[:title].blank? }
  end

  def build_text
    lines = ["=== VEILLE HEBDOMADAIRE REN0VATE — #{Date.today.strftime('%d/%m/%Y')} ===\n"]

    @results.each do |result|
      lines << "\n--- #{result[:source]} (#{result[:region]}) ---"

      if result[:error]
        lines << "  ⚠️ Source indisponible cette semaine (#{result[:error].truncate(60)})"
        next
      end

      if result[:items].empty?
        lines << "  Aucun article récupéré."
        next
      end

      result[:items].each_with_index do |item, i|
        lines << "\n  #{i + 1}. #{item[:title]}"
        lines << "     Date : #{item[:date]}" if item[:date].present?
        lines << "     #{item[:description]}" if item[:description].present?
      end
    end

    lines.join("\n")
  end
end
