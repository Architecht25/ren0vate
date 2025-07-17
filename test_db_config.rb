#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== Configuration de base de données ==="
puts "Environment: #{Rails.env}"
puts "Database config: #{ActiveRecord::Base.connection_db_config.configuration_hash}"
puts "Current user: #{ActiveRecord::Base.connection.execute('SELECT current_user').first['current_user']}"
puts "Database name: #{ActiveRecord::Base.connection.current_database}"
