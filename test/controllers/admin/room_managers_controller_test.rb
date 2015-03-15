require 'test_helper'

class Admin::RoomManagersControllerTest < ActionController::TestCase
  
 if Settings.optional_modules.streaming
  test "unlogged user should not be redirected" do
    get :index
    assert_not_authorized
  end
  
  roles = ["admin", "operador_de_streaming"]

  roles.each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :index
      assert_response :success
      assert_template "index"
    end
  end
  
  ["periodista", "visitante", "comentador_oficial", "secretaria_interior", \
   "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "colaborador", "room_manager"].each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :index
       assert_not_authorized     
     end     
  end
  
  # this action has been moved to users_controller
  # test "streaming operator cannot edit room_management information" do
  #   login_as("operador_de_streaming")
  #   get :edit, :id => users(:room_manager)
  #   assert_not_authorized
  #   assert_no_difference 'RoomManagement.count' do
  #     put :update, :id => users(:room_manager), :room_manager => {:stream_flow_ids => [stream_flows(:sf_one).id, stream_flows(:sf_two).id]}
  #   end
  #   assert_not_authorized
  # end
 end
end
