#!/usr/bin/env ruby

puts "🔍 DIAGNOSTIC FINAL - Test direct URL Cloudinary"
puts "=" * 60

# URL Cloudinary que nous connaissons déjà (nouvelle avec config publique)
test_url = "http://res-5.cloudinary.com/dtdelexhd/image/upload/v1/development/3cjl1ia7krie35ucnarvwqcu0wtg.pdf?_a=BACCg+Ev"

puts "🌐 Test de l'URL Cloudinary:"
puts "   #{test_url}"

require 'net/http'
require 'uri'

begin
  uri = URI(test_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = false # HTTP pour ce test

  request = Net::HTTP::Get.new(uri)
  request['User-Agent'] = 'RenOvate-App/1.0'

  puts "\n📡 Envoi de la requête..."
  response = http.request(request)

  puts "\n📊 RÉSULTATS:"
  puts "   Status Code: #{response.code} #{response.message}"
  puts "   Content-Type: #{response['content-type']}"
  puts "   Content-Length: #{response['content-length']}"
  puts "   Content-Disposition: #{response['content-disposition']}"
  puts "   Cache-Control: #{response['cache-control']}"

  if response.code == '200'
    content_sample = response.body[0..50] rescue "N/A"
    puts "\n✅ SUCCÈS - CONTENU RÉCUPÉRÉ!"
    puts "   Début du contenu: #{content_sample.inspect}"

    if content_sample.start_with?('%PDF')
      puts "   🎯 CONTENT PDF VALIDE - LE PROBLÈME N'EST PAS CLOUDINARY!"
      puts "   ➡️  Le problème est probablement dans le navigateur/JavaScript"
    else
      puts "   ❌ CONTENU NON-PDF - Cloudinary retourne autre chose"
    end
  elsif response.code.start_with?('3')
    puts "\n🔄 REDIRECTION DÉTECTÉE:"
    puts "   Location: #{response['location']}"
  else
    puts "\n❌ ERREUR CLOUDINARY:"
    puts "   Message: #{response.body[0..200] rescue 'N/A'}"
  end

rescue => e
  puts "\n💥 ERREUR RÉSEAU:"
  puts "   #{e.message}"
  puts "   Type: #{e.class}"
end

puts "\n" + "=" * 60
puts "🎯 CONCLUSION:"
puts "   Si status 200 + contenu PDF = Problème côté client (navigateur/JS)"
puts "   Si erreur = Problème côté Cloudinary"
puts "=" * 60
