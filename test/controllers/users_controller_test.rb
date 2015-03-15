require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  roles = ["periodista", "visitante", "politician_lehendakaritza", "colaborador", "jefe_de_gabinete", "miembro_que_modifica_noticias", "comentador_oficial", "secretaria_interior", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "should show user page for #{role}" do
      get :show, :id => users(role).id
      assert_response :success
    end
  end

  ["periodista_sin_aprobar", "admin"].each do |role|
    test "should show redirect to home instead of show user page for #{role}" do
      get :show, :id => users(role).id
      assert_response :redirect
    end
  end

end
