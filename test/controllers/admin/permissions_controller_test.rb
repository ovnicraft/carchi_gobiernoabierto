require 'test_helper'

class Admin::PermissionsControllerTest < ActionController::TestCase

  test "redirect for unlogged" do
    get :show
    assert_not_authorized
  end
  
  roles = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", "jefe_de_gabinete", "jefe_de_prensa", "colaborador", "admin", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "#{role} cannot administer permissions" do
      login_as(role)
      get :show, :user_id => users(:periodista).id
      assert_not_authorized
      
      get :edit, :user_id => users(:periodista).id
      assert_not_authorized
      
      put :update, :user_id => users(:miembro_que_crea_noticias).id, :perm => {:news => {:create => 1, :complete => 1}, :events => {:create_private => 1}}
      assert_not_authorized
    end
  end  
  
  test "superadmin can view permissions" do
    login_as("superadmin")
    get :show, :user_id => users(:periodista).id
    assert_response :success
    assert_template "show"
    assert_select "ul.edit_links li a.edit" do
      assert_select "[href=?]", /.+permissions\/edit/
    end
  end
  
  test "miembro_que_crea_noticias has correct permissions" do
    login_as("superadmin")
    get :edit, :user_id => users(:miembro_que_crea_noticias).id
    assert_response :success
    assert_template "edit"
    assert_select "input[type=checkbox][checked=checked]", :checked => true, :count => 1
    assert_select "input#perm_news_create", :checked => true
  end
  
  test "i can change permissions for miembro_que_crea_noticias" do
    login_as("superadmin")
    user = users(:miembro_que_crea_noticias)
    assert_equal 1, user.permissions.count
    
    
    assert user.can?("create", "news")
    assert !user.can?("complete", "news")
    assert !user.can?("create_private", "events")
    
    put :update, :user_id => user.id, :perm => {:news => {:create => 1, :complete => 1}, :events => {:create_private => 1}}
    assert_redirected_to admin_user_path(user)
    
    assert_equal 3, user.permissions.count

    assert user.can?("create", "news")
    assert user.can?("complete", "news")
    assert user.can?("create_private", "events")
  end
  
  test "should delete all permissions of one user" do
    login_as("superadmin")
    user = users(:miembro_con_permisos_de_todo_tipo)
    assert_equal 3, user.permissions.count
    get :edit, :user_id => user.id
    assert_select "input[type=checkbox][checked=checked]", :count => 3
    assert_select "input#perm_news_create[checked=checked]"
    assert_select "input#perm_comments_official[checked=checked]"
    assert_select "input#perm_events_create_irekia[checked=checked]"
    
    put :update, :user_id => user.id # quitamos todos los permisos
    assert_redirected_to admin_user_path(assigns(:user))
    assert_equal 0, assigns(:user).permissions.count
  end
  

end
