class IntelligenceScraperService
  include HTTParty

  SOURCES = [
    {
      key:    'abex',
      label:  'ABEX — Indice de reconstruction',
      url:    'https://abex.be/feed/',
      region: 'Belgique',
      type:   :rss
    },
    {
      key:    'google_news_renov',
      label:  'Google News — Rénovation & Énergie Belgique',
      url:    'https://news.google.com/rss/search?q=%22r%C3%A9novation%22+%22Belgique%22+OR+%22EPBD%22+OR+%22primes+%C3%A9nergie%22&hl=fr&gl=BE&ceid=BE:fr',
      region: 'Belgique',
      type:   :rss
    },
    {
      key:            'embuild',
      label:          'Embuild — Construction Belgique',
      url:            'https://embuild.be/fr/actualit%C3%A9s',
      region:         'Belgique',
      type:           :html,
      title_selector: '.content__title',
      base_url:       'https://embuild.be'
    },
    {
      key:            'urban_brussels',
      label:          'Urban.brussels — Permis & Urbanisme',
      url:            'https://urban.brussels/fr/news/index',
      region:         'Bruxelles',
      type:           :html,
      title_selector: 'h3.card__title a',
      link_selector:  'h3.card__title a',
      base_url:       'https://urban.brussels'
    },
    {
      key:            'bxl_env_press',
      label:          'Bruxelles Environnement — Communiqués de presse',
      url:            'https://press.environment.brussels/',
      region:         'Bruxelles',
      type:           :html,
      title_selector: 'h2[class*="StoryCard_title"]',
      link_selector:  'a[class*="StoryCard_link"]',
      base_url:       'https://press.environment.brussels'
    }
  ].freeze

  MAX_ITEMS_PER_SOURCE = 5
  REQUEST_TIMEOUT      = 15

  def initialize
    @results = []
  end

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
      timeout:          REQUEST_TIMEOUT,
      headers:          { 'User-Agent' => 'Ren0vate-IntelligenceBot/1.0' },
      follow_redirects: true
    )

    return [] unless response.success?

    case source[:type]
    when :rss  then parse_rss(response.body)
    when :html then parse_html(response.body, source)
    else []
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn "IntelligenceScraperService — timeout #{source[:url]}"
    []
  end

  def parse_rss(xml_body)
    doc   = Nokogiri::XML(xml_body)
    items = doc.css('item, entry')

    items.first(MAX_ITEMS_PER_SOURCE).map do |item|
      title       = item.at_css('title')&.text&.strip
      description = item.at_css('description, summary, content')&.text&.strip
      pub_date    = item.at_css('pubDate, published, updated')&.text&.strip
      link        = item.at_css('link')&.text&.strip || item.at_css('link')&.attr('href')

      description = Nokogiri::HTML(description).text.strip if description&.include?('<')
      description = description&.truncate(300)

      { title: title, description: description, date: pub_date, url: link }.compact
    end.reject { |i| i[:title].blank? }
  end

  def parse_html(html_body, source)
    doc          = Nokogiri::HTML(html_body)
    title_nodes  = doc.css(source[:title_selector])
    link_nodes   = source[:link_selector] ? doc.css(source[:link_selector]) : []
    base         = source[:base_url].to_s

    title_nodes.first(MAX_ITEMS_PER_SOURCE).each_with_index.filter_map do |node, i|
      title = node.text.gsub(/\s+/, ' ').strip
      next if title.length < 10

      href = (link_nodes[i] || node).attr('href')&.strip
      url  = if href.present?
               href.start_with?('http') ? href : "#{base}#{href}"
             end

      { title: title, url: url }.compact
    end
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
        lines << "     #{item[:description]}"  if item[:description].present?
      end
    end

    lines.join("\n")
  end
end
