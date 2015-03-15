require 'capybara_integration_test_helper'

class EmbedCommentsFlowTest < ActionDispatch::IntegrationTest
  def teardown
  #   Capybara.reset_sessions!
  #   Capybara.use_default_driver
    FakeWeb.clean_registry
    visit("/es/logout")
  end

  def setup
    Capybara.current_driver = :selenium
    Capybara.default_wait_time = 5 # wait 5 seconds for response

    # FakeWeb permite stubbear las llamadas a URL-s que se hacen a través de Net::HTTP
    # Aquí lo usamos para stubbear las llamadas al API de twitter, fb y g+
    FakeWeb.allow_net_connect = %r[^http?://127.0.0.1] # permitir sólo las llamadas a localhost
  end

  context "with external client" do
    setup do
      @client = external_comments_clients(:euskadinet)
    end

    context "with external item" do
      setup do
        @item = external_comments_items(:euskadinet_item1)
      end

      context "logged in person" do
        setup do
          # Login como visitante
          user = users(:visitante)
          visit '/es/login'
          fill_login_form(user)
          assert_equal account_path(locale: 'es'), current_path
        end

        should "see comments list and add new comment" do
          visit "/es/embed/comment?client=#{@client.code}&url=\"#{@item.url}\""
          assert page.has_selector?('div#acomments')
          assert page.has_selector?('div#acomments div.count')
          assert page.has_selector?('form#new_comment')
          assert !page.has_content?("Nuevo comentario")

          fill_in 'comment', :with => "Nuevo comentario"
          click_button 'Comentar'

          assert page.has_content?("Tu comentario ha sido enviado")
        end

      end # fin logged in person
            
            
      context "logged in admin" do
        setup do
          # Login como admin
          user = users(:admin)
          visit '/es/login'
          fill_login_form(user)
          assert_equal '/es/sadmin/news', current_path
        end

        should "see comments list and add new comment" do
          visit "/es/embed/comment?client=#{@client.code}&url=\"#{@item.url}\""
          assert page.has_selector?('div#acomments')
          assert page.has_selector?('div#acomments div.count')
          assert page.has_selector?('form#new_comment')
          assert !page.has_content?("Nuevo comentario")

          fill_in 'comment', :with => "Nuevo comentario"
          click_button 'Comentar'

          assert page.has_content?("Nuevo comentario")
        end
 
        context "logged in department member" do
            setup do
              # Login como miembro_que_crea_noticias
              user = users(:miembro_que_crea_noticias)
              # NO tiene permiso para hacer comentarios.
              assert !user.can_create?("comments")
              visit '/es/login'
              fill_login_form(user)
              assert_equal '/es/sadmin/news', current_path
            end

            should "see comments list and add new comment" do
              visit "/es/embed/comment?client=#{@client.code}&url=\"#{@item.url}\""
              assert page.has_selector?('div#acomments')
              assert page.has_selector?('div#acomments div.count')
              assert page.has_selector?('form#new_comment')
              assert !page.has_content?("Nuevo comentario")

              fill_in 'comment', :with => "Nuevo comentario"
              click_button 'Comentar'

              assert page.has_content?("Tu comentario NO se ha enviado.")
            end
         end 
      end

      context "not logged user" do
        setup do
          @comments_counter = Comment.count
          visit '/es/logout'
          
          visit "/es/embed/comment?client=#{@client.code}&url=\"#{@item.url}\""          
          fill_in "comment", :with => "Mi comentario"
          click_button "Comentar"

          within_window(page.driver.browser.window_handles.last) do
            page.has_selector?('a#login_window_link')
            page.has_css?('form.login')
          end          
          
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
        end
          
        should "login as visitante and send comment", :js => true do
          # Rellenamos el formulario de login
          fill_login_form(users(:visitante))
          # Volver a la ventana inicial porque la del formulario está cerrada.
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
          
          # Al enviar el formiulario  de login se envía también el comentario.
          assert page.has_content?("Tu comentario ha sido enviado")
          assert_equal @comments_counter + 1, Comment.count 
        end

        should "login as admin and send comment", :js => true do
          # Rellenamos el formulario de login
          fill_login_form(users(:admin))
          
          # Volver a la ventana inicial porque la del formulario está cerrada.
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
          
          # Al enviar el formiulario  de login se envía también el comentario.
          assert page.has_content?("Mi comentario")
          assert_equal @comments_counter + 1, Comment.count 
        end
        
        if Rails.application.secrets["twitter"]
        should "login as twitter user and send comment" do
          twitter_user = users(:twitter_user)
          
          # Stub para las llamadas a twitter
          FakeWeb.register_uri(:post, 'https://api.twitter.com/oauth/request_token', :body => 'oauth_token=fake&oauth_token_secret=fake') 
          
          FakeWeb.register_uri(:post, 'https://api.twitter.com/oauth/access_token', :body => 'oauth_token=fake&oauth_token_secret=fake') 
          FakeWeb.register_uri(:get, 'https://api.twitter.com/1.1/account/verify_credentials.json', :body => {'name' => twitter_user.name, 'screen_name' => twitter_user.screen_name, 'location' => ""}.to_json)
          # Después del update del usuario conectado, se llama fill_lat_lng_data que por su parte llama a esta URL
          FakeWeb.register_uri(:any, /http:\/\/maps.googleapis.com\/maps\/api\/geocode*/, :body => {'status' => "OK", 'results' => []}.to_json)

          # Click en el enlace para asignar el return_to          
          click_link "Conectar via Twitter"
          
          # Volver a la ventana inicial porque la del formulario está cerrada.
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)          
                    
          # Al enviar el formiulario  de login se envía también el comentario.
          assert page.has_content?("Tu comentario ha sido enviado")
          assert_equal @comments_counter + 1, Comment.count   
        end
        end
        
        should "recover password and login as visitante and send comment", :js => true do
          click_link "Recupérala aquí"
          assert page.has_content?("Por favor, introduce tu dirección de email")
          fill_in "email", :with => users(:visitante).email
          click_button 'Enviar'       
          assert page.has_content? 'Te hemos enviado tu información de acceso por email'
          assert_equal embed_login_path, current_path
          
          # Rellenamos el formulario de login
          fill_login_form(users(:visitante))
          # Volver a la ventana inicial porque la del formulario está cerrada.
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
          
          # Al enviar el formiulario  de login se envía también el comentario.
          assert_equal true, page.has_content?("Tu comentario ha sido enviado")
          assert_equal @comments_counter + 1, Comment.count 
        end
      end
    end        
    
    
    context "with exported irekia news" do
      setup do
        @item = external_comments_items(:euskadinet_item_irekia_news)
      end
      
      context "logged in person" do
        setup do
          # Login como visitante
          user = users(:visitante)
          visit '/es/login'
          fill_login_form(user)
          assert_equal account_path(locale: 'es'), current_path
        end
      
        should "see comments list and add new comment" do
          visit "/es/embed/comment?news_id=#{@item.irekia_news_id}&url=\"#{@item.url}\""
          assert page.has_selector?('div#acomments')
          assert page.has_selector?('div#acomments div.count')
          assert page.has_selector?('form#new_comment')
          assert !page.has_content?("Nuevo comentario")
      
          fill_in 'comment', :with => "Nuevo comentario"
          click_button 'Comentar'
      
          assert page.has_content?("Tu comentario ha sido enviado")
        end
      
      end # fin logged in person
    end

    context "with euskadinetNewsID" do
      setup do
        @item = external_comments_items(:euskadinet_item1)
      end
      
      context "logged in person" do
        setup do
          # Login como visitante
          user = users(:visitante)
          visit '/es/login'
          fill_login_form(user)
          assert_equal account_path(locale: 'es'), current_path
        end
      
        should "see comments list and add new comment" do
          visit "/es/embed/comment?content_local_id=#{@item.content_local_id}&url=\"#{@item.url}\""
          assert page.has_selector?('div#acomments')
          assert page.has_selector?('div#acomments div.count')
          assert page.has_selector?('form#new_comment')
          assert !page.has_content?("Nuevo comentario")
      
          fill_in 'comment', :with => "Nuevo comentario"
          click_button 'Comentar'
      
          assert page.has_content?("Tu comentario ha sido enviado")
        end
      
      end # fin logged in person
    end

  end
  
end
