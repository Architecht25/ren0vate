#!/usr/bin/env ruby
# Script pour découper automatiquement le fichier primes.rb Wallonie

require 'fileutils'

def extract_wallonie_primes_sections
  input_file = "db/seeds/wallonie/primes.rb"
  output_dir = "db/seeds/wallonie/primes"

  # Créer le dossier de destination
  FileUtils.mkdir_p(output_dir)

  content = File.read(input_file)
  lines = content.split("\n")

  # Mappings des sections vers les noms de fichiers
  section_mappings = {
    "AUDIT" => "audit",
    "TOITURE" => "toiture",
    "MURS" => "murs",
    "SOLS" => "sols",
    "MENUISERIES" => "menuiseries",
    "INSTALLATIONS" => "installations",
    "CHAUFFAGE" => "chauffage",
    "VENTILATION" => "ventilation",
    "AMÉLIORATIONS CHAUFFAGE" => "ameliorations_chauffage",
    "ECS (EAU CHAUDE SANITAIRE)" => "ecs"
  }

  current_section = nil
  current_content = []
  header_written = false

  lines.each_with_index do |line, index|
    # Détecter une nouvelle section
    if line.match(/^# === (.+) ===$/)
      section_name = $1.strip

      # Sauvegarder la section précédente
      if current_section && section_mappings[current_section]
        save_section(current_section, current_content, output_dir, section_mappings)
      end

      # Initialiser la nouvelle section
      current_section = section_name
      current_content = []
      header_written = false
      puts "📁 Section détectée: #{section_name}"
    elsif current_section
      # Ajouter le header de section une seule fois
      if !header_written
        current_content << generate_section_header(current_section)
        current_content << ""
        current_content << line # la ligne # === XXX ===
        header_written = true
      else
        current_content << line
      end
    end
  end

  # Sauvegarder la dernière section
  if current_section && section_mappings[current_section]
    save_section(current_section, current_content, output_dir, section_mappings)
  end

  puts "✅ Extraction terminée - #{section_mappings.size} modules créés"
end

def generate_section_header(section_name)
  clean_name = section_name.gsub(/[()]/, '').strip
  <<~HEADER.chomp
  # =====================================================
  # PRIMES WALLONIE - #{clean_name.upcase}
  # =====================================================
  # Module pour les primes #{clean_name.downcase}
  # =====================================================

  puts "🏗️ Création des primes #{clean_name} Wallonie..."
  HEADER
end

def save_section(section_name, content, output_dir, mappings)
  filename = mappings[section_name]
  return unless filename

  filepath = File.join(output_dir, "#{filename}.rb")

  # Ajouter le footer
  content << ""
  content << "puts \"✅ Primes #{section_name} Wallonie créées avec succès\""

  File.write(filepath, content.join("\n"))
  puts "💾 Sauvegardé: #{filepath} (#{content.size} lignes)"
end

# Exécution
if __FILE__ == $0
  puts "🚀 Début extraction primes Wallonie..."
  extract_wallonie_primes_sections
end
