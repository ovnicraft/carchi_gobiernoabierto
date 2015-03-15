require 'test_helper'

class Sadmin::AccountControllerTest < ActionController::TestCase
  
  context "edit personal account" do 
    ["periodista", "visitante", "politician_one"].each do |role|
      should "should not edit sadmin account for #{role}" do
        login_as(role)
        get :edit
        assert_response :redirect
        assert_redirected_to new_session_url
      end  
    end  
    
    roles = ["colaborador", "comentador_oficial", "secretaria_interior", \
     "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "room_manager", "admin", "politician_interior", "politician_lehendakaritza"]
    roles << "operador_de_streaming" if Settings.optional_modules.streaming
    roles.each do |role|
      should "should redirect to admin for #{role}" do
        login_as(role)
        get :edit
        assert_response :success
        assert_template 'edit'
      end
    end
  end
  
end  
