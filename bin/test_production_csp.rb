#!/usr/bin/env ruby
require "net/http"
require "uri"
require "json"

# Test script pour vérifier que le dashboard admin fonctionne en production avec CSP

puts "🚀 Testing production CSP configuration..."

# Configuration
base_url = "http://localhost:3001"
test_endpoints = [
  "/",
  "/admin/dashboard"
]

def test_endpoint(url, expected_content = nil)
  begin
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    puts "\n📍 Testing: #{url}"
    puts "   Status: #{response.code} #{response.message}"

    # Vérifier les headers CSP
    csp_header = response['Content-Security-Policy']
    if csp_header
      puts "   ✅ CSP Header present: #{csp_header[0..100]}..."

      # Vérifier si script-src contient nonce
      if csp_header.include?("script-src") && csp_header.include?("nonce-")
        puts "   ✅ Script nonce detected in CSP"
      else
        puts "   ⚠️  No script nonce in CSP (might be 'unsafe-inline')"
      end
    else
      puts "   ❌ No CSP Header found"
    end

    # Vérifier le contenu si spécifié
    if expected_content && response.code == "200"
      if response.body.include?(expected_content)
        puts "   ✅ Expected content found: #{expected_content}"
      else
        puts "   ❌ Expected content missing: #{expected_content}"
      end
    end

    # Vérifier les nonces dans le HTML
    if response.body.include?('nonce="')
      nonces = response.body.scan(/nonce="([^"]+)"/)
      puts "   ✅ #{nonces.length} nonce(s) found in HTML"
      nonces.each_with_index do |nonce, i|
        puts "      Nonce #{i+1}: #{nonce.first[0..20]}..."
      end
    else
      puts "   ⚠️  No nonces found in HTML"
    end

    return response.code == "200"
  rescue => e
    puts "   ❌ Error: #{e.message}"
    return false
  end
end

# Tests
puts "\n" + "="*50
puts "🧪 PRODUCTION CSP TESTS"
puts "="*50

success_count = 0
total_tests = test_endpoints.length

test_endpoints.each do |endpoint|
  url = "#{base_url}#{endpoint}"
  expected = endpoint == "/admin/dashboard" ? "Actions de Sécurité" : nil

  if test_endpoint(url, expected)
    success_count += 1
  end
end

puts "\n" + "="*50
puts "📊 RESULTS: #{success_count}/#{total_tests} tests passed"

if success_count == total_tests
  puts "✅ All tests passed! Production CSP configuration looks good."
  exit 0
else
  puts "❌ Some tests failed. Check the CSP configuration."
  exit 1
end
