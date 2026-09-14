require "test_helper"

class MarketingDraftJobTest < ActiveJob::TestCase
  class FakeAnthropicClient
    def initialize(response: nil, error: nil)
      @response = response
      @error = error
    end

    def messages
      self
    end

    def create(**)
      raise @error if @error
      @response
    end
  end

  FakeTextBlock = Struct.new(:type, :text)
  FakeMessage   = Struct.new(:content)

  def build_report(week_of: "2026-W#{SecureRandom.hex(2)}", status: "completed")
    IntelligenceReport.create!(week_of: week_of, status: status, analysis: "Analyse de test", sources_count: 3)
  end

  setup do
    @previous_key = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "test-key"
  end

  teardown do
    ENV["ANTHROPIC_API_KEY"] = @previous_key
  end

  test "MarketingDraftJob est bien enfileué sur la queue default avec l'id du rapport" do
    report = build_report

    assert_enqueued_with(job: MarketingDraftJob, args: [ report.id ], queue: "default") do
      MarketingDraftJob.perform_later(report.id)
    end
  end

  test "ignore silencieusement un rapport introuvable ou non complété" do
    report = build_report(status: "pending")

    assert_nothing_raised { MarketingDraftJob.perform_now(report.id) }
    assert_not MarketingWeek.exists?(week_of: report.week_of)

    assert_nothing_raised { MarketingDraftJob.perform_now(-1) }
  end

  test "gère une erreur du service Claude sans planter silencieusement et sans lever d'exception" do
    report = build_report
    fake_client = FakeAnthropicClient.new(error: StandardError.new("Claude indisponible"))

    result = nil
    assert_nothing_raised do
      stub_class_method(Anthropic::Client, :new, fake_client) do
        result = MarketingDraftJob.perform_now(report.id)
      end
    end

    # Le job doit malgré tout persister un MarketingWeek (draft vide) plutôt que
    # de planter tout le pipeline de veille -> marketing.
    week = MarketingWeek.find_by(week_of: report.week_of)
    assert week.present?, "le job doit créer un MarketingWeek même si tous les appels Claude échouent"
    assert_nil week.linkedin_post
    assert_nil week.instagram_post
    assert_nil week.facebook_post
    assert_nil week.article
  end

  test "construit l'article et les posts sociaux quand Claude répond normalement" do
    report = build_report

    responses = [
      FakeMessage.new([ FakeTextBlock.new(:text, "TITRE: Un titre\nEXTRAIT: Un extrait\nCATEGORIE: primes\n---\n# Un titre\nContenu de l'article.") ]),
      FakeMessage.new([ FakeTextBlock.new(:text, "Post LinkedIn de test") ]),
      FakeMessage.new([ FakeTextBlock.new(:text, "Post Instagram de test") ]),
      FakeMessage.new([ FakeTextBlock.new(:text, "Post Facebook de test") ])
    ]

    call_index = 0
    fake_new = ->(**_kwargs) {
      client = Object.new
      client.define_singleton_method(:messages) { client }
      response = responses[call_index]
      call_index += 1
      client.define_singleton_method(:create) { |**| response }
      client
    }

    stub_class_method(Anthropic::Client, :new, fake_new) do
      MarketingDraftJob.perform_now(report.id)
    end

    week = MarketingWeek.find_by(week_of: report.week_of)
    assert week.present?
    assert_equal "Post LinkedIn de test", week.linkedin_post
    assert_equal "Post Instagram de test", week.instagram_post
    assert_equal "Post Facebook de test", week.facebook_post
    assert week.article.present?
    assert_equal "Un titre", week.article.title
    assert_equal "primes", week.article.category
  end

  test "ne recrée pas de MarketingWeek si une semaine existe déjà" do
    report = build_report
    MarketingWeek.create!(week_of: report.week_of, status: "draft")

    assert_no_difference "MarketingWeek.count" do
      MarketingDraftJob.perform_now(report.id)
    end
  end
end
