require File.expand_path('../boot', __FILE__)

require 'rails/all'

# populate ENV with values from Example yml config files
require_relative './load_env.rb'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Example
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Load custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths << "#{config.root}/app/services"
    config.autoload_paths << "#{config.root}/lib"
    config.autoload_paths << "#{config.root}/lib/constraints"
    config.autoload_paths << "#{config.root}/lib/devise"
    config.autoload_paths << "#{config.root}/lib/plugins"
    config.autoload_paths << "#{config.root}/lib/validators"

    require 'exceptions'

    # Custom middlewares
    config.middleware.insert_before ActionDispatch::ParamsParser, 'Api::V1::CatchJsonParseErrors'

    # Custom Exceptions app
    config.exceptions_app = self.routes

    # Load additional configuration
    Gibbon::API.throws_exceptions = false
    config.wowza = Rails.application.config_for(:wowza).deep_symbolize_keys
  end
end
