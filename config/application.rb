require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Production doesn't use bundler
# you've limited to :test, :development, or :production.
if ENV['RAILS_ENV'] != 'production'
  Bundler.require(*Rails.groups)
else
  # Dependencies to load before starting rails in production
  require 'devise'
  require 'jquery-rails'
  require 'coffee-rails'
  require 'state_machine'
  require 'nokogiri'
  require 'will_paginate'
end

module WebDNS
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.time_zone = 'Europe/Athens'

    # Store/Read localtime from the database
    config.active_record.default_timezone = :local
    config.active_record.schema_format = :sql

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.autoload_paths << Rails.root.join('lib')

    config.x = {}
  end

  def self.settings
    Application.config.x
  end

end
