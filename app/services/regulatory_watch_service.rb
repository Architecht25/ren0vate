# Vérifie si le contenu d'une page réglementaire officielle a changé depuis la
# dernière vérification (hash du texte visible, hors nav/scripts/styles — pas de
# détection de "nouvel article", juste "cette page a-t-elle bougé ?").
#
# À la première vérification d'une source, on enregistre juste le hash de
# référence (baseline) — pas d'alerte, on n'a rien à comparer.
class RegulatoryWatchService
  include HTTParty

  REQUEST_TIMEOUT = 20

  Result = Struct.new(:source, :changed, :error, keyword_init: true) do
    def changed?  = changed == true
    def error?    = error.present?
  end

  # Vérifie toutes les sources actives, met à jour leur hash/date, et renvoie
  # la liste des Result pour lesquelles un changement a été détecté.
  def self.check_all(http_client: HTTParty)
    RegulatorySource.active.map { |source| new(source, http_client: http_client).check }
  end

  # http_client injectable pour les tests (doit répondre à .get comme HTTParty)
  def initialize(source, http_client: HTTParty)
    @source = source
    @http_client = http_client
  end

  def check
    content_hash = fetch_content_hash

    if content_hash.nil?
      @source.update(last_checked_at: Time.current)
      return Result.new(source: @source, changed: false, error: "Impossible de récupérer la page")
    end

    previous_hash = @source.last_content_hash
    changed = previous_hash.present? && previous_hash != content_hash

    @source.update(
      last_content_hash: content_hash,
      last_checked_at: Time.current,
      last_changed_at: changed ? Time.current : @source.last_changed_at
    )

    Result.new(source: @source, changed: changed, error: nil)
  rescue => e
    Rails.logger.warn "RegulatoryWatchService — échec #{@source.url}: #{e.message}"
    @source.update(last_checked_at: Time.current)
    Result.new(source: @source, changed: false, error: e.message)
  end

  private

  def fetch_content_hash
    response = @http_client.get(
      @source.url,
      timeout: REQUEST_TIMEOUT,
      headers: { "User-Agent" => "Ren0vate-RegulatoryWatchBot/1.0" },
      follow_redirects: true
    )
    return nil unless response.success?

    Digest::SHA256.hexdigest(extract_relevant_text(response.body))
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error, SocketError
    nil
  end

  # Texte visible uniquement (hors script/style/nav/header/footer — souvent du
  # bruit qui change sans rapport avec la réglementation elle-même : menus,
  # bannières cookies, widgets de partage...).
  def extract_relevant_text(html)
    doc = Nokogiri::HTML(html)
    doc.css("script, style, nav, header, footer, noscript").remove
    doc.text.squish
  end
end
