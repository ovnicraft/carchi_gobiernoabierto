require 'test_helper'

class Embed::SessionsControllerTest < ActionController::TestCase
  test "should show new session form" do
    get :new
    assert_response :success
  end
  
  roles = ["admin", "periodista", "visitante", "comentador_oficial", "secretaria_interior", "jefe_de_gabinete", "jefe_de_prensa", "colaborador", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "should log in as #{role}" do
      user = users(role)
      post :create, {:email => user.email, :password => 'test'}
      assert_response :success
      assert_template "logged_in"
      
      assert_select "p", :text => /Estamos enviando tu comentario/
    end
  end  
  
  test "should show errors if login data is not valid" do
    user =  users(:visitante)
    post :create, {:email => user.email, :password => "testxxx"}
    assert_response :success
    assert_template "new"   
    assert_select "div.alert-error", :text => I18n.t('session.Email_incorrecto')
  end
  
  test "should show wait for activation for visitante_sin_activar" do
    user = users(:visitante_sin_activar)
    post :create, {:email => user.email, :password => "testxxx"}
    assert_response :success
    assert_template "waiting_for_approval"       
    
    assert_select "a", :href => email_activation_session_path(:email => user.email, :return_to => embed_login_path)
  end
  
  test "should show password reset form" do
    get :password_reset
    assert_response :success
  end
  
end
