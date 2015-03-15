require 'test_helper'

class Admin::EventLocationsControllerTest < ActionController::TestCase
  test "unlogged user should not be redirected" do
    get :index
    assert_not_authorized
  end
  
  ["admin"].each do |role|
    test "get index if logged as #{role}" do
      login_as(role)  
      get :index
      assert_response :success
      assert_template "index"
    end
  end
  
  roles = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", \
   "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "colaborador", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :index
       assert_not_authorized     
     end     
  end
  
  
  test "show location" do
    login_as(:admin)
    get :show, :id => event_locations(:el_lehendakaritza).id
    assert_response :success
  end

  test "edit location" do
    login_as(:admin)
    get :edit, :id => event_locations(:el_lehendakaritza).id
    assert_response :success
    
    assert_select 'input#event_location_address'
  end

  test "new location" do
    login_as(:admin)
    get :new
    assert_response :success
    
    assert_select 'input#event_location_address'
  end
  
  test "create location" do
    login_as(:admin)
    
    assert_difference "EventLocation.count" do
      post :create, :event_location => location_params
    end
      
    assert_response :redirect
  end


  test "update location" do
    login_as(:admin)
    
    assert_no_difference "EventLocation.count" do
      put :update, :id => event_locations(:el_lehendakaritza).id, :event_location => location_params
    end
      
    assert_response :redirect
    assert assigns(:location)
    assert_equal "Pamplona", assigns(:location).city
  end

  private 
  def location_params
    {:place => "Sede Pamplona", :city => "Pamplona", :address => "Gran Vía", :lat => "42.820680", :lng => "-1.644545"}
  end  
end
