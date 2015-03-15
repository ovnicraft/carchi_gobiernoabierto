require 'test_helper'

class Admin::OrganizationsControllerTest < ActionController::TestCase
  
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
  
  # 2DO
  
  test "should get index" do
    login_as('admin')
    get :index
    assert_response :success
    assert_not_nil assigns(:organizations)
  end
  
  test "should get new organization" do
    login_as('admin')
    get :new
    assert_response :success
    assert assigns(:organization).is_a?(Organization)
  end
  
  test "should get new department" do
    login_as('admin')
    get :new, :d => 1
    assert_response :success
    assert assigns(:organization).is_a?(Department)
  end
  
  test "should create organization" do
    login_as('admin')
    assert_difference('Organization.count') do
      post :create, :organization => {:name_es => "New organization"}
    end
  
    assert_redirected_to admin_organization_path(assigns(:organization))
  end

  test "should create department" do
    login_as('admin')
    assert_difference('Department.count') do
      post :create, :organization => {:name_es => "New department", :tag_name=> "_new"}
    end
    assert_redirected_to admin_organization_path(assigns(:organization))
  end
  
  test "should show organization" do
    login_as('admin')
    get :show, :id => organizations(:lehendakaritza).id
    assert_response :success
  end
  
  test "should get edit" do
    login_as('admin')
    get :edit, :id => organizations(:emakunde).id
    assert_response :success
  end
  
  test "should update organization" do
    login_as('admin')
    put :update, :id => organizations(:emakunde).id, :organization => {:name_es => "Emakunde 2" }
    assert_redirected_to admin_organization_path(assigns(:organization))
  end
  
  # test "should destroy organization" do
  #   assert_difference('Organization.count', -1) do
  #     delete :destroy, :id => admin_organizations(:lehendakaritza).id
  #   end
  # 
  #   assert_redirected_to admin_organizations_path
  # end
end
