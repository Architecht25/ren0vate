require "test_helper"

module BusinessIntelligence
  class IntelligenceScraperServiceTest < ActiveSupport::TestCase
    FakeResponse = Struct.new(:success, :body) do
      def success? = success
    end

    RSS_SAMPLE = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <title>Nouvelle réforme des primes énergie</title>
            <description><![CDATA[<p>Un <b>résumé</b> avec du HTML.</p>]]></description>
            <pubDate>Mon, 08 Sep 2026 08:00:00 GMT</pubDate>
            <link>https://example.be/article-1</link>
          </item>
          <item>
            <title></title>
            <description>Item sans titre, doit être rejeté</description>
            <link>https://example.be/article-2</link>
          </item>
        </channel>
      </rss>
    XML

    HTML_SAMPLE = <<~HTML
      <html>
        <body>
          <div class="content__title"><a href="/actualites/mon-article">Un article suffisamment long</a></div>
          <div class="content__title"><a href="https://embuild.be/full-url">Encore un article assez long</a></div>
          <div class="content__title">Trop court</div>
        </body>
      </html>
    HTML

    setup { @service = BusinessIntelligence::IntelligenceScraperService.new }

    test "parse_rss extrait titre, description nettoyée du HTML, date et lien, en ignorant les items sans titre" do
      items = @service.send(:parse_rss, RSS_SAMPLE)

      assert_equal 1, items.length
      item = items.first
      assert_equal "Nouvelle réforme des primes énergie", item[:title]
      assert_equal "Un résumé avec du HTML.", item[:description]
      assert_equal "https://example.be/article-1", item[:url]
      assert item[:date].present?
    end

    test "parse_html extrait titre et URL absolue en filtrant les titres trop courts" do
      source = { title_selector: ".content__title a", base_url: "https://embuild.be" }

      items = @service.send(:parse_html, HTML_SAMPLE, source)

      assert_equal 2, items.length
      assert_equal "Un article suffisamment long", items[0][:title]
      assert_equal "https://embuild.be/actualites/mon-article", items[0][:url]
      assert_equal "Encore un article assez long", items[1][:title]
      assert_equal "https://embuild.be/full-url", items[1][:url]
    end

    test "fetch_all agrège les sources, gère les échecs et construit le texte formaté (HTTP mocké)" do
      success_response = FakeResponse.new(true, RSS_SAMPLE)
      failure_response  = FakeResponse.new(false, nil)

      call_count = 0
      fake_get = ->(*_args, **_kwargs) {
        call_count += 1
        call_count.odd? ? success_response : failure_response
      }
      stub_class_method(HTTParty, :get, fake_get) do
        result = @service.fetch_all

        assert result[:sources].is_a?(Array)
        assert_equal BusinessIntelligence::IntelligenceScraperService::SOURCES.length, result[:sources].length
        assert result[:total_items] >= 0
        assert_includes result[:formatted_text], "VEILLE HEBDOMADAIRE REN0VATE"
      end
    end

    test "fetch_all consigne une erreur par source sans planter si le client HTTP explose" do
      stub_class_method(HTTParty, :get, ->(*_args, **_kwargs) { raise Net::OpenTimeout, "boom" }) do
        result = nil
        assert_nothing_raised { result = @service.fetch_all }

        assert_equal 0, result[:total_items]
        assert result[:sources].all? { |s| s[:items].empty? }
      end
    end
  end
end
