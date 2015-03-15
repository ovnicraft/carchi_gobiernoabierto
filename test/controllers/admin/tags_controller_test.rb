require 'test_helper'

class Admin::TagsControllerTest < ActionController::TestCase
  
  test "unlogged user should not be redirected" do
    get :index
    assert_not_authorized
  end
  
  ["admin"].each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :index
      assert_response :success
      assert_template "index"
    end
  end
  
  # tofix: "colaborador" doesn't work
  users = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", \
   "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "colaborador", "room_manager"]
  users << "operador_de_streaming" if Settings.optional_modules.streaming
  users.each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :index
       assert_not_authorized     
     end     
  end

end
