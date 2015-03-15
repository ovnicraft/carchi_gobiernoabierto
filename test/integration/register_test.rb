require 'capybara_integration_test_helper'

class RegisterTest < ActionDispatch::IntegrationTest
  def teardown
  #   Capybara.reset_sessions!
  #   Capybara.use_default_driver
    visit("/es/logout")
  end

  def setup
    Capybara.current_driver = :selenium
    Capybara.default_wait_time = 5 # wait 5 seconds for response
    visit("/es/logout")
  end
  
  context "new irekia user" do

   if Settings.optional_modules.proposals
    should "register through Register link" do      
      # Empezamos en la página de peticiones ciudadanas
      visit proposals_path(locale: 'es')

      # Nos registramos
      click_link "Regístrate"
      click_link I18n.t('people.crea_tu_cuenta', :site_name => Settings.site_name)
      assert page.has_content? "Rellena tus datos y comienza a participar"
      
      fill_in "user_email", :with => "nuevo_usuario@efaber.net"
      fill_in "user_password", :with => "123456"
      fill_in "user_password_confirmation", :with => "123456"
      fill_in "user_name", :with => "Nuevo"
      fill_in "user_last_names", :with => "Usuario"
      fill_in "user_zip", :with => "48600"
      check "user_normas_de_uso"
      click_button "Crear mi cuenta"
      
      assert page.has_content? "¡Gracias por registrarte!"
      click_link "Volver a navegar"
      
      # Volvemos a la página de noticias
      assert_equal proposals_path, current_path
    end

    should "register through login block for petitions" do
      # Empezamos en la página de peticiones ciudadanas
      visit proposals_path()
      
      # Click en Crea una petición abre la ventana de login
      click_link "Crea una petición"
      
      # Esperamos hasta que se cargue el formulario de login
      within_window(page.driver.browser.window_handles.last) do
        page.has_css?('form.login')
      end          
      assert_equal 2, page.driver.browser.window_handles.size # dos ventanas
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
            
      click_link I18n.t('people.crea_tu_cuenta', :site_name => Settings.site_name)
      assert_equal 1, page.driver.browser.window_handles.size # queda sólo una ventana
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
      
      assert page.has_content? "Rellena tus datos y comienza a participar"
      
      fill_in "user_email", :with => "nuevo_usuario@efaber.net"
      fill_in "user_password", :with => "123456"
      fill_in "user_password_confirmation", :with => "123456"
      fill_in "user_name", :with => "Nuevo"
      fill_in "user_last_names", :with => "Usuario"
      fill_in "user_zip", :with => "48600"
      check "user_normas_de_uso"
      click_button "Crear mi cuenta"
      
      assert page.has_content? "¡Gracias por registrarte!"
      click_link "Volver a navegar"
      
      # Volvemos a la página de noticias
      assert_equal proposals_path, current_path
    end
   end

    should "register through login block for comments" do
      # Empezamos en la página de una noticia
      start_path = news_path(id: documents(:featured_news).id)
      visit start_path

      fill_in 'comment', :with => "Nuevo comentario"
      click_button 'Comentar'      
      
      # Esperamos hasta que se cargue el formulario de login
      within_window(page.driver.browser.window_handles.last) do
        page.has_css?('form.login')
      end          
      assert_equal 2, page.driver.browser.window_handles.size # dos ventanas
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
            
      click_link I18n.t('people.crea_tu_cuenta', :site_name => Settings.site_name)
      assert_equal 1, page.driver.browser.window_handles.size # queda sólo una ventana
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
      assert page.has_content? "Rellena tus datos y comienza a participar"
      
      fill_in "user_email", :with => "nuevo_usuario@efaber.net"
      fill_in "user_password", :with => "123456"
      fill_in "user_password_confirmation", :with => "123456"
      fill_in "user_name", :with => "Nuevo"
      fill_in "user_last_names", :with => "Usuario"
      fill_in "user_zip", :with => "48600"
      check "user_normas_de_uso"
      click_button "Crear mi cuenta"
      
      assert page.has_content? "¡Gracias por registrarte!"
      click_link "Volver a navegar"
      
      # Volvemos a la página de noticias
      assert_equal start_path, current_path
    end
    
  end

end
