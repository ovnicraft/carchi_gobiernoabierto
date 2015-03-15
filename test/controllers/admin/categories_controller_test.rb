require 'test_helper'

class Admin::CategoriesControllerTest < ActionController::TestCase
  test "unlogged user should not be redirected" do
    get :index
    assert_not_authorized
  end
  
  
  ["admin"].each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :edit, :tree_id => trees(:web_tv).id, :id => categories(:cat_de_webtv).id, :lang => "es"
      assert_response :success
      assert_template "edit"
    end
  end
  
  roles = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", \
   "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "colaborador", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :index, :tree_id => trees(:web_tv).id
       assert_not_authorized     
     end     
  end
end
