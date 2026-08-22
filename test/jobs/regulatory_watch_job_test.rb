require "test_helper"

class RegulatoryWatchJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  FakeWatchService = Struct.new(:results) do
    def check_all(**) = results
  end

  def build_source
    RegulatorySource.create!(url: "https://example.be/#{SecureRandom.hex(4)}", label: "Source test")
  end

  test "envoie un email si au moins une source a changé" do
    source = build_source
    changed_result = RegulatoryWatchService::Result.new(source: source, changed: true, error: nil)
    fake_service = FakeWatchService.new([ changed_result ])

    assert_enqueued_email_with AdminMailer, :regulatory_sources_changed, args: [ [ source ] ] do
      RegulatoryWatchJob.perform_now(watch_service: fake_service)
    end
  end

  test "n'envoie aucun email si rien n'a changé" do
    source = build_source
    stable_result = RegulatoryWatchService::Result.new(source: source, changed: false, error: nil)
    fake_service = FakeWatchService.new([ stable_result ])

    assert_no_enqueued_emails do
      RegulatoryWatchJob.perform_now(watch_service: fake_service)
    end
  end

  test "n'envoie pas d'email pour une source en échec seule (juste un log)" do
    source = build_source
    errored_result = RegulatoryWatchService::Result.new(source: source, changed: false, error: "timeout")
    fake_service = FakeWatchService.new([ errored_result ])

    assert_no_enqueued_emails do
      RegulatoryWatchJob.perform_now(watch_service: fake_service)
    end
  end
end
