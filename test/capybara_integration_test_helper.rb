require 'test_helper'

require "capybara/rails"

module ActionDispatch
  class IntegrationTest
    include Capybara::DSL
  end
end

def http_auth_headers
  {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(Rails.application.secrets['http_auth']['user_name'], Rails.application.secrets['http_auth']['password'])} if Rails.application.secrets['http_auth']
end

def fill_login_form(user)
  fill_in 'Email', :with => user.email
  fill_in 'Contraseña', :with => 'test'
  click_button 'Entrar'
end

#
# Ajustes para los tests de JS con Capybara:
#
# http://blog.plataformatec.com.br/2011/12/three-tips-to-improve-the-performance-of-your-test-suite/
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

# Fin de Ajustes para los tests de JS:
class ActionDispatch::Integration::Session
  def url_for_with_default_locale(options)
    options = { locale: I18n.locale }.merge(options)
    url_for_without_default_locale(options)
  end

  alias_method_chain :url_for, :default_locale
end
