require "prawn"

module AccountExports
  # Export complet d'un compte (usage admin, avant suppression d'un compte) :
  # un ZIP (envoyé en flux) contenant
  #   - 00-synthese.pdf : profil, biens, chantiers, demandes de primes, simulations
  #   - fichiers/       : tous les fichiers originaux (ActiveStorage) rattachés à
  #                       l'utilisateur, ses biens, chantiers, demandes et suivis.
  # Aucune condition de plan. Les fichiers sont joints tels quels (pas de
  # conversion en PDF) : plus fidèle pour les scans, photos et PDF administratifs.
  #
  # Inclus (décision du 23/11/2026) : tous les attributs, y compris hash du mot de
  # passe, tokens, secrets 2FA, `national_number` et `iban` (déchiffrés). Le ZIP
  # est donc sensible : ne pas l'envoyer par mail non chiffré.
  class ArchiveService
    # Seul le bruit technique est exclu.
    EXCLUDED_ATTRIBUTES = %w[id extracted_data embedding updated_at].freeze
    MAX_VALUE_LENGTH = 300

    def initialize(user)
      @user = user
      @seen_blobs = {}
      @used_names = Hash.new(0)
      @skipped = []
    end

    # Écrit l'archive dans un ZipKit::Streamer (envoi en flux : les premiers octets
    # partent tout de suite, ce qui évite le timeout H12 de 30 s de Heroku, et rien
    # n'est accumulé en mémoire — un compte peut peser plusieurs centaines de Mo).
    # Le PDF part en premier ; les fichiers suivent un par un.
    def stream_to(zip)
      entries = plan_entries
      zip.write_deflated_file("00-synthese.pdf") { |sink| sink << build_pdf(entries.map(&:last)) }

      entries.each do |attachment, path, _label|
        begin
          data = attachment.download
        rescue StandardError => e
          @skipped << "#{path} (#{e.class})"
          next
        end
        zip.write_stored_file("fichiers/#{path}") { |sink| sink << data }
        data = nil
      end

      return if @skipped.empty?

      zip.write_deflated_file("fichiers-non-recuperes.txt") { |sink| sink << @skipped.join("\n") }
    end

    private

    # [[attachment, chemin dans le ZIP, ligne d'index]] — sans télécharger quoi que ce soit.
    def plan_entries
      collect_files.filter_map do |folder, record, attachment|
        next if @seen_blobs[attachment.blob_id]

        @seen_blobs[attachment.blob_id] = true
        path = unique_path(folder, attachment.filename.to_s)
        [attachment, path, "#{path}  (#{record.class.name} ##{record.id})"]
      end
    end

    # --- Collecte des fichiers -------------------------------------------------

    def collect_files
      out = []
      add = lambda do |folder, record|
        next unless record.class.respond_to?(:reflect_on_all_attachments)

        record.class.reflect_on_all_attachments.each do |refl|
          record.public_send(refl.name).attachments.each { |a| out << [folder, record, a] } if refl.macro == :has_many_attached
          if refl.macro == :has_one_attached
            a = record.public_send(refl.name)
            out << [folder, record, a] if a.attached?
          end
        end
      end

      @user.documents.find_each { |d| add.call("profil/documents", d) }
      @user.properties.each do |property|
        pf = "biens/#{slug(property.titre.presence || property.try(:adresse).presence || "bien-#{property.id}")}"
        add.call(pf, property)
        property.documents.find_each { |d| add.call("#{pf}/documents", d) }
        property.projects.each do |project|
          cf = "#{pf}/chantiers/#{slug(project.nom.presence || "chantier-#{project.id}")}"
          project.documents.find_each { |d| add.call("#{cf}/documents", d) }
          project.project_documents.includes(:current_version).find_each do |pd|
            v = pd.current_version
            add.call("#{cf}/documents-v2", v) if v
          end
          add.call("#{cf}/pv-reception", project.pv_reception) if project.pv_reception
          project.reserves.find_each { |r| add.call("#{cf}/reserves", r) }
          project.site_log_entries.find_each { |e| add.call("#{cf}/journal-chantier", e) }
        end
      end
      all_requests.each do |req|
        rf = "demandes-primes/#{slug(req.title.presence || "demande-#{req.id}")}-#{req.id}"
        add.call(rf, req)
        req.documents.find_each { |d| add.call("#{rf}/documents", d) }
        req.request_progresses.each do |rp|
          add.call("#{rf}/suivi", rp)
          rp.complement_requests.each { |c| add.call("#{rf}/complements", c) }
        end
      end
      out
    end

    def all_requests
      ids = @user.requests.pluck(:id) | Request.where(property_id: @user.properties.select(:id)).pluck(:id)
      Request.where(id: ids).order(:created_at)
    end

    def unique_path(folder, filename)
      base = "#{folder}/#{filename}"
      n = (@used_names[base] += 1)
      return base if n == 1

      ext = File.extname(filename)
      "#{folder}/#{File.basename(filename, ext)}-#{n}#{ext}"
    end

    def slug(str)
      str.to_s.parameterize.presence || "sans-nom"
    end

    # --- PDF de synthèse -------------------------------------------------------

    def build_pdf(file_index)
      Prawn::Document.new(page_size: "A4", margin: [40, 50, 40, 50],
                          info: { Title: "Export du compte #{@user.email}", Author: "Ren0vate", CreationDate: Time.current }) do |pdf|
        @pdf = pdf
        title("Export des données — #{@user.email}")
        text_line("Généré le #{I18n.l(Time.current, format: :long)}", size: 9)

        section("Profil")
        dump(@user)

        @user.properties.each do |property|
          section("Bien : #{property.titre.presence || property.try(:adresse) || property.id}")
          dump(property)
          property.projects.each do |project|
            subsection("Chantier : #{project.nom}")
            dump(project)
            related(project.factures, "Factures / devis (factures)")
            related(project.devis_donnees, "Devis")
            related(project.simulations, "Simulations")
          end
          related(property.simulations.where(project_id: nil), "Simulations du bien")
        end

        section("Demandes de primes")
        reqs = all_requests
        text_line("Aucune demande.") if reqs.empty?
        reqs.each do |req|
          subsection("Demande : #{req.title.presence || "##{req.id}"}")
          dump(req)
          related(req.request_progresses, "Suivi administratif")
          req.request_progresses.each { |rp| related(rp.complement_requests, "Compléments demandés") }
        end

        section("Autres données")
        related(@user.simulations, "Simulations")
        related(@user.pret_wallonie_dossiers, "Dossiers prêt Wallonie")

        section("Index des fichiers joints (dossier fichiers/)")
        text_line("Aucun fichier.") if file_index.empty?
        file_index.each { |l| text_line(l, size: 8) }
      end.render
    end

    def title(str)
      @pdf.text clean(str), size: 18, style: :bold
      @pdf.move_down 6
    end

    def section(str)
      @pdf.start_new_page if @pdf.cursor < 120
      @pdf.move_down 14
      @pdf.text clean(str), size: 14, style: :bold, color: "1a56b0"
      @pdf.stroke_horizontal_rule
      @pdf.move_down 6
    end

    def subsection(str)
      @pdf.start_new_page if @pdf.cursor < 80
      @pdf.move_down 8
      @pdf.text clean(str), size: 11, style: :bold
      @pdf.move_down 3
    end

    def text_line(str, size: 9)
      @pdf.text clean(str), size: size
    end

    def dump(record)
      record.class.attribute_names.each do |key|
        next if EXCLUDED_ATTRIBUTES.include?(key)

        value = safe_read(record, key)
        next if value.blank?

        text_line("#{key.humanize} : #{format_value(value)}")
      end
      @pdf.move_down 4
    end

    # Un champ chiffré (Active Record Encryption) dont le contenu est corrompu ou
    # vide ne doit pas faire échouer tout l'export (bug du 23/11/2026, compte 75).
    def safe_read(record, key)
      record.read_attribute(key)
    rescue ActiveRecord::Encryption::Errors::Base
      "[illisible : déchiffrement impossible]"
    end

    def related(scope, label)
      records = scope.to_a
      return if records.empty?

      subsection("#{label} (#{records.size})")
      records.each do |r|
        dump(r)
        @pdf.stroke_color "cccccc"
        @pdf.stroke_horizontal_rule
        @pdf.stroke_color "000000"
        @pdf.move_down 4
      end
    end

    def format_value(value)
      v = value.respond_to?(:iso8601) ? value.iso8601 : value.to_s
      v.length > MAX_VALUE_LENGTH ? "#{v[0, MAX_VALUE_LENGTH]}…" : v
    end

    # Polices PDF standard = WinAnsi : on remplace tout caractère non encodable
    # (emoji, etc.) pour éviter une Prawn::Errors::IncompatibleStringEncoding.
    def clean(str)
      str.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
    end
  end
end
