class SitemapController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @pages = sitemap_pages

    respond_to do |format|
      format.xml { render layout: false }
    end
  end

  private

  def sitemap_pages
    base_url = Rails.application.config.force_ssl ? "https://" : "http://"
    base_url += request.host_with_port

    pages = []

    # Pages principales pour chaque locale
    I18n.available_locales.each do |locale|
      locale_prefix = locale.to_s == I18n.default_locale.to_s ? "" : "/#{locale}"

      # Page d'accueil
      pages << {
        url: "#{base_url}#{locale_prefix}/",
        lastmod: Date.current,
        changefreq: 'weekly',
        priority: 1.0
      }

      # Pages régionales particuliers
      pages << {
        url: "#{base_url}#{locale_prefix}/flandre",
        lastmod: Date.current,
        changefreq: 'weekly',
        priority: 0.9
      }

      pages << {
        url: "#{base_url}#{locale_prefix}/bruxelles",
        lastmod: Date.current,
        changefreq: 'weekly',
        priority: 0.9
      }

      pages << {
        url: "#{base_url}#{locale_prefix}/wallonie",
        lastmod: Date.current,
        changefreq: 'weekly',
        priority: 0.9
      }

      # Pages régionales entreprises
      pages << {
        url: "#{base_url}#{locale_prefix}/flandre_entreprises",
        lastmod: Date.current,
        changefreq: 'weekly',
        priority: 0.8
      }

      pages << {
        url: "#{base_url}#{locale_prefix}/bruxelles_entreprises",
        lastmod: Date.current,
        changefreq: 'weekly',
        priority: 0.8
      }

      pages << {
        url: "#{base_url}#{locale_prefix}/wallonie_entreprises",
        lastmod: Date.current,
        changefreq: 'weekly',
        priority: 0.8
      }

      # Page pricing
      pages << {
        url: "#{base_url}#{locale_prefix}/pricing",
        lastmod: Date.current,
        changefreq: 'monthly',
        priority: 0.7
      }

      # Pages légales
      pages << {
        url: "#{base_url}#{locale_prefix}/legal",
        lastmod: Date.current,
        changefreq: 'yearly',
        priority: 0.3
      }

      pages << {
        url: "#{base_url}#{locale_prefix}/privacy",
        lastmod: Date.current,
        changefreq: 'yearly',
        priority: 0.3
      }

      # Documents officiels des primes
      pages << {
        url: "#{base_url}#{locale_prefix}/prime_document_templates",
        lastmod: Date.current,
        changefreq: 'monthly',
        priority: 0.6
      }
    end

    # Ajouter les primes individuelles si elles existent
    if defined?(Prime)
      Prime.distinct.pluck(:slug).each do |slug|
        I18n.available_locales.each do |locale|
          locale_prefix = locale.to_s == I18n.default_locale.to_s ? "" : "/#{locale}"
          pages << {
            url: "#{base_url}#{locale_prefix}/primes/#{slug}",
            lastmod: Date.current,
            changefreq: 'monthly',
            priority: 0.5
          }
        end
      end
    end

    pages
  end
end
