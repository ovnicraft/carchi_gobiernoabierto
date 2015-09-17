require File.expand_path('../boot', __FILE__)

require 'rails/all'
require File.expand_path('config/initializers/public_ip.rb')

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OpenIrekia
  class Application < Rails::Application
    irekia_config          = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'irekia.yml'))).result)[Rails.env].symbolize_keys
    config.multimedia      = irekia_config[:multimedia].symbolize_keys.reverse_merge(:url => File.join('http://', PublicIp.get, 'data'))
    config.external_urls   = irekia_config[:external_urls] ? irekia_config[:external_urls].symbolize_keys : {}
    config.rtmp_server     = irekia_config[:rtmp_server]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/lib/)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    config.active_record.observers = :user_action_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Quito'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.enforce_available_locales = false
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :es

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Consider using this to precompile all assets
    config.assets.precompile << Proc.new do |path|
      if path =~ /\.(css|js)\z/
        full_path = Rails.application.assets.resolve(path).to_path
        app_assets_path = Rails.root.join('app', 'assets').to_path
        vendor_assets_path = Rails.root.join('vendor', 'assets').to_path
        if full_path.starts_with?(app_assets_path) || full_path.starts_with?(vendor_assets_path)
          puts "including asset: " + full_path
          true
        else
          puts "excluding asset: " + full_path
          false
        end
      else
        false
      end
    end

    # Caching
    config.action_controller.page_cache_directory = "#{Rails.root.to_s}/public/cache"
    config.action_controller.cache_store = :file_store, "#{Rails.root.to_s}/cache/fragment/"

    # Strong parameters
    config.action_controller.action_on_unpermitted_parameters = :raise

    config.middleware.insert_before Rack::Runtime, Rack::URISanitizer
    config.middleware.use ExceptionNotification::Rack, 
      :email => {
        :email_prefix => "[OpenIrekia #{Rails.env} Error] ",
        :sender_address => '"OpenIrekia Error" <openirekia@gobiernoabierto.carchi.gob.ec>',
        :exception_recipients => %w(debug@alabs.org)
      }
    # Email errors raised in rake tasks
    ExceptionNotifier::Rake.configure

  end

end

require 'ri_cal'

