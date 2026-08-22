require "test_helper"

class RegulatoryWatchServiceTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:success, :body) do
    def success? = success
  end

  # Faux client HTTP injecté (voir RegulatoryWatchService#initialize) — évite de
  # dépendre d'une gem de mock ou de monkeypatcher HTTParty dans les tests.
  FakeHttpClient = Struct.new(:response) do
    def get(*) = response
  end

  def build_source(url: "https://example.be/primes")
    RegulatorySource.create!(label: "Source test", url: url, region: "wallonie")
  end

  test "première vérification : enregistre un hash de référence sans détecter de changement" do
    source = build_source
    client = FakeHttpClient.new(FakeResponse.new(true, "<html><body><p>Contenu initial</p></body></html>"))

    result = RegulatoryWatchService.new(source, http_client: client).check
    assert_not result.changed?
    assert_not result.error?

    assert source.reload.last_content_hash.present?
    assert source.last_checked_at.present?
    assert_nil source.last_changed_at
  end

  test "détecte un changement quand le contenu diffère du hash précédent" do
    source = build_source
    source.update!(last_content_hash: Digest::SHA256.hexdigest("Ancien contenu"))
    client = FakeHttpClient.new(FakeResponse.new(true, "<html><body><p>Nouveau contenu très différent</p></body></html>"))

    result = RegulatoryWatchService.new(source, http_client: client).check
    assert result.changed?
    assert source.reload.last_changed_at.present?
  end

  test "pas de changement détecté si le contenu est identique" do
    source = build_source
    expected_hash = Digest::SHA256.hexdigest("Contenu stable")
    source.update!(last_content_hash: expected_hash)
    client = FakeHttpClient.new(FakeResponse.new(true, "<html><body><p>Contenu stable</p></body></html>"))

    result = RegulatoryWatchService.new(source, http_client: client).check
    assert_not result.changed?
  end

  test "ignore le nav/header/footer/script pour éviter les faux positifs" do
    source = build_source
    source.update!(last_content_hash: Digest::SHA256.hexdigest("Contenu principal"))
    html = <<~HTML
      <html>
        <head><script>var x = Math.random();</script></head>
        <body>
          <nav>Menu qui change à chaque déploiement</nav>
          <header>Bannière cookies v#{rand(9999)}</header>
          <p>Contenu principal</p>
          <footer>© 2026</footer>
        </body>
      </html>
    HTML
    client = FakeHttpClient.new(FakeResponse.new(true, html))

    result = RegulatoryWatchService.new(source, http_client: client).check
    assert_not result.changed?, "le nav/header/footer/script ne doivent pas déclencher un faux changement"
  end

  test "renvoie une erreur si la page ne répond pas correctement (success? false)" do
    source = build_source
    client = FakeHttpClient.new(FakeResponse.new(false, nil))

    result = RegulatoryWatchService.new(source, http_client: client).check
    assert result.error?
    assert_not result.changed?
    assert source.reload.last_checked_at.present?
  end

  test "check_all ne vérifie que les sources actives" do
    active = build_source(url: "https://example.be/active")
    inactive = build_source(url: "https://example.be/inactive").tap { |s| s.update!(active: false) }
    client = FakeHttpClient.new(FakeResponse.new(true, "<html><body>ok</body></html>"))

    results = RegulatoryWatchService.check_all(http_client: client)
    checked_ids = results.map { |r| r.source.id }
    assert_includes checked_ids, active.id
    assert_not_includes checked_ids, inactive.id
  end
end
