#!/usr/bin/env ruby

puts '🔍 TEST URL PUBLIQUE CLOUDINARY DIRECTE'
puts '=' * 50

# Configuration Cloudinary depuis les variables d'environnement
cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
folder = 'development'
key = '50x9lcihbb723oxfxf8g42kdlggp'  # Key du dernier PDF

# URLs publiques possibles à tester
test_urls = [
  "https://res.cloudinary.com/#{cloud_name}/raw/upload/v1/#{folder}/#{key}.pdf",
  "https://res.cloudinary.com/#{cloud_name}/image/upload/v1/#{folder}/#{key}.pdf",
  "https://res.cloudinary.com/#{cloud_name}/auto/upload/v1/#{folder}/#{key}.pdf",
  "https://res.cloudinary.com/#{cloud_name}/raw/upload/#{folder}/#{key}.pdf"
]

require 'net/http'
require 'uri'

test_urls.each_with_index do |test_url, index|
  puts "\n🧪 TEST #{index + 1}/#{test_urls.length}:"
  puts "   URL: #{test_url}"

  begin
    uri = URI(test_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'RenOvate-App/1.0'

    response = http.request(request)

    puts "   Status: #{response.code} #{response.message}"

    if response.code == '200'
      content_sample = response.body[0..10] rescue "N/A"
      puts "   ✅ SUCCÈS! Contenu: #{content_sample.inspect}"

      if content_sample.start_with?('%PDF')
        puts "   🎯 PDF VALIDE ACCESSIBLE!"
        puts "   📡 URL FONCTIONNELLE: #{test_url}"
        break  # On a trouvé la bonne URL
      end
    elsif response.code.start_with?('4')
      puts "   ❌ Erreur client (#{response.code})"
    elsif response.code.start_with?('3')
      puts "   🔄 Redirection vers: #{response['location']}"
    end

  rescue => e
    puts "   💥 Erreur réseau: #{e.message}"
  end
end

puts "\n" + "=" * 50
