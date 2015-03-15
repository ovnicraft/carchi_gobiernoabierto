require 'test_helper'

class Admin::AlbumsControllerTest < ActionController::TestCase
  test "unlogged user should not be redirected" do
    get :index
    assert_not_authorized
  end
  
  ["admin", "colaborador"].each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :index
      assert_response :success
      assert_template "index"
    end
  end
  
  roles = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", \
   "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :index
       assert_not_authorized
     end
  end
end
