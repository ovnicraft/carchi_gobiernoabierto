require 'capybara_integration_test_helper'

# TODO: 
# * tests para los casos en los que el login falla
# * probar el stub con Faraday para ver si así se pueden stubbear también los redirect_to

class EmbedCommentsFlowTest < ActionDispatch::IntegrationTest
  def teardown
  #   Capybara.reset_sessions!
  #   Capybara.use_default_driver
    FakeWeb.clean_registry
  end

  def setup
    Capybara.current_driver = :selenium
    Capybara.default_wait_time = 5 # wait 5 seconds for response

    # FakeWeb permite stubbear las llamadas a URL-s que se hacen a través de Net::HTTP
    # Aquí lo usamos para stubbear las llamadas al API de twitter, fb y g+
    FakeWeb.allow_net_connect = %r[^http?://127.0.0.1] # permitir sólo las llamadas a localhost
  end

  if Rails.application.secrets["twitter"]
  context "twitter user" do
    setup do
      twitter_user = users(:twitter_user)
      
      # Stub para las llamadas a twitter
      FakeWeb.register_uri(:post, 'https://api.twitter.com/oauth/request_token', :body => 'oauth_token=fake&oauth_token_secret=fake') 
    
      FakeWeb.register_uri(:post, 'https://api.twitter.com/oauth/access_token', :body => 'oauth_token=fake&oauth_token_secret=fake') 
      FakeWeb.register_uri(:get, 'https://api.twitter.com/1.1/account/verify_credentials.json', :body => {'name' => twitter_user.name, 'screen_name' => twitter_user.screen_name, 'location' => ""}.to_json)
      # Después del update del usuario conectado, se llama fill_lat_lng_data que por su parte llama a esta URL
      FakeWeb.register_uri(:any, /http:\/\/maps.googleapis.com\/maps\/api\/geocode*/, :body => {'status' => "OK", 'results' => []}.to_json)
    end
    
    should "login" do
      visit "/es/embed/login?return_to=#{embed_logged_path(locale:'es')}" 
      click_link "Conectar via Twitter"
      
      page.has_css?('div.logged_in')
    end  
  end
  end

  if Rails.application.secrets["twitter"]
  context "facebook user" do
    setup do
      facebook_user = users(:facebook_user)
      
      # Stub para las llamadas a facebook
      # NO se puede hacer stub de la llamada a facebook a través de FakeWeb porque
      # la llamada no se hace con Net::HTTP
      # Así que cambiamos el controller para que al llamar al create en el entorno de tests
      # haga redirect a finalize_fb_session_path(:code => "fake")
            
      FakeWeb.register_uri(:get, %r|https://graph\.facebook\.com/oauth/access_token|, 
                                 :body => "client_id=185167851514439&redirect_uri=fake&client_secret=fakee0&code=fake")
      FakeWeb.register_uri(:get, %r|https://graph\.facebook\.com/me|, 
                                 :body => {"id" => facebook_user.fb_id,
                                          "name" => facebook_user.name,
                                          "first_name" => facebook_user.name.split(" ").first,
                                          "last_name" => facebook_user.name.split(" ").last,
                                          "link" => facebook_user.url,
                                          "gender" => "female",
                                          "timezone" => 1,
                                          "locale" => "es_ES",
                                          "verified" => true}.to_json)
    end
    
    should "login" do
      visit "/es/embed/login?return_to=#{embed_logged_path(locale:'es')}" 
      
      # Click en el link para asiganr session[:return_to]
      click_link "Conectar via Facebook"
            
      page.has_css?('div.logged_in')
    end  
    
  end
  end

  if Rails.application.secrets["googleplus"]
  context "googleplus user" do
    setup do
      googleplus_user = users(:googleplus_user)
      
      # Stub para las llamadas a google+
      # NO se puede hacer stub de la llamada a facebook a través de FakeWeb porque
      # la llamada no se hace con Net::HTTP
      # Así que cambiamos el controller para que al llamar al create en el entorno de test
      # haga redirect a finalize_googleplus_session_path(:code => "fake")
            
      FakeWeb.register_uri(:post, "https://accounts.google.com/o/oauth2/token", 
                                  :body => File.open("#{Rails.root}/test/fixtures/googleplus/token_response.json").read())
                                  
      FakeWeb.register_uri(:get, "https://www.googleapis.com/discovery/v1/apis/oauth2/v2/rest", 
                                 :body => File.open("#{Rails.root}/test/fixtures/googleplus/discovery_rest_response_data.json").read(),
                                 :content_type => 'application/json')
                                 
      FakeWeb.register_uri(:get, "https://www.googleapis.com/oauth2/v2/userinfo", 
                                 :body => {"id" => googleplus_user.googleplus_id,
                                           "given_name" => googleplus_user.name.split(" ").first,
                                           "family_name" => googleplus_user.name.split(" ").last}.to_json)
    end
    
    should "login" do
      visit "/es/embed/login?return_to=#{embed_logged_path(locale:'es')}" 
      
      # Click en el link para asiganr session[:return_to]
      click_link "Conectar via Google +"
      page.has_css?('div.logged_in')
    end  
    
  end
  end


end
