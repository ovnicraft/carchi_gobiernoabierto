require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase

  test "redirect for unlogged" do
    get :index
    assert_not_authorized
  end

  users = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", \
   "jefe_de_gabinete", "jefe_de_prensa", "colaborador", "room_manager", "admin", "colaborador_externo"]
  users << 'operador_de_streaming' if Settings.optional_modules.streaming
  users.each do |role|
    test "redirect if logged as #{role}" do
      login_as(role)
      get :index
      assert_not_authorized
    end
  end

  test "get index for superadmins" do
     login_as(:superadmin)
     get :index
     assert_response :success
     assert_template "admin/users/index"
  end

  User::TYPES.each do |t, pretty_name|
    test "should show users of type #{t} for admin" do
      login_as(:superadmin)
      get :index, :t => t
      assert_response :success
    end
  end



  test "bann user" do
    login_as(:superadmin)
    u = users(:jefe_de_gabinete)
    post :update, :id => u.id, :user => {:status => "vetado"}
    assert_response :redirect

    updated = User.find(u.id)
    assert_equal "vetado", updated.status
    assert_equal u.department_id, updated.department_id
  end

  test "update user data" do
    login_as(:superadmin)
    u = users(:jefe_de_gabinete)

    new_params = {:name => "JG", :last_names => "Xxx", :telephone => "555-555-555", :email => 'jg@xxx.com', :department_id => organizations(:gobierno_vasco).id, :status => "aprobado"}
    post :update, :id => u.id, :user => new_params
    assert_response :redirect

    updated = User.find(u.id)
    new_params.each do |key, value|
      assert_equal value, updated.send(key.to_s)
    end
  end

  test "should send access info to journalist after approval" do
    login_as(:superadmin)
    user = users(:periodista_sin_aprobar)
    assert_difference 'ActionMailer::Base.deliveries.size', + 1 do
      put :update, :id => user.id, :locale => "eu",
          :user => {:type => "Journalist", :status => "aprobado", :alerts_locale => "es" }
    end

    m = ActionMailer::Base.deliveries.last
    assert_equal I18n.t('notifier.welcome', :name => Settings.site_name), m.subject
    assert_equal m.to[0], 'periodista_sin_aprobar@efaber.net'
    assert_match 'Hola Un periodista sin aprobar', m.body.to_s
  end

  # Deprecated porque ahora los permisos de editar usuario y editar permiso van juntos
  # test "admin should not see permissions edit link" do
  #   login_as("admin")
  #   get :show, :id => users(:jefe_de_gabinete).id
  #   assert_response :success
  #   assert_template "show"
  #   assert_select "ul.edit_links li a.edit" do
  #     assert_select "[href=?]", /.+permissions\/edit/, :count => 0
  #   end
  # end

  test "superadmin should see permissions edit link" do
    login_as("superadmin")
    get :show, :id => users(:jefe_de_gabinete).id
    assert_response :success
    assert_template "show"
    assert_select "ul.edit_links li a.edit" do
      assert_select "[href=?]", /.+permissions\/edit/
    end
  end

  # test "admin does not administer users" do
  #   login_as("admin")
  #   !helper.can_access?("users")
  # end
  #
  # test "superadmin administers users" do
  #   login_as("superadmin")
  #   helper.can_access?("users")
  # end

  test "should show media for journalists list" do
    login_as(:superadmin)
    get :index, :t => 'Journalist'
    assert_response :success

    assert_select "table.users_list" do
      assert_select 'th', 'Nombre'
    end

    assert_select 'table.last_logins' do
      assert_select 'th', 'Cuándo'
    end
  end

  test "should find twitter user" do
    login_as(:superadmin)
    twitter_user = users(:twitter_user)


    get :index, :t => 'Person', :q => twitter_user.name
    assert_response :success

    assert assigns(:users)
    assert assigns(:users).detect {|u| u.eql?(twitter_user)}
  end
  
  context "comments" do
    context "visitante" do
      setup do
        login_as(:superadmin)
        @user = users(:visitante)
      end
      
      should "show all comments" do
        get :show, :id => @user.id, :subtab => "comments"
        assert_response :success
        
        assert assigns(:comments)
        
        assert assigns(:comments).detect {|comment| comment.commentable.is_a?(ExternalComments::Item)}
        assert assigns(:comments).detect {|comment| comment.commentable.is_a?(Document)}        
        
        assert_select "fieldset.comments" do
          assert_select "table.comments" do
            assert_select "tr", :count => @user.comments.length+1
          end
        end
      end
    end
  end
end


