# config/initializers/sprockets_manifest.rb

Rails.application.config.assets.configure do |env|
  # on force le manifest sur le répertoire public/assets, passé en String
  manifest_path = Rails.root.join("public", "assets").to_s
  env.instance_variable_set(:@manifest, Sprockets::Manifest.new(env, manifest_path))
end
