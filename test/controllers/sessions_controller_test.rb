require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  test "should email activation email and redirect to login path" do
    visitante_sin_activar = users(:visitante_sin_activar)
    assert_difference 'ActionMailer::Base.deliveries.size', + 1 do
      get :email_activation, :email => visitante_sin_activar.email
    end
    assert_response :redirect
    assert_redirected_to login_path

    m = ActionMailer::Base.deliveries.last
    assert_equal I18n.t('notifier.welcome', :name => Settings.site_name), m.subject
    assert_equal m.to[0],   visitante_sin_activar.email
    assert_match "Bienvenido/a a #{Settings.site_name}", m.body.to_s
  end

  test "should email activation email and redirect to embed login path" do
    visitante_sin_activar = users(:visitante_sin_activar)
    assert_difference 'ActionMailer::Base.deliveries.size', + 1 do
      get :email_activation, :email => visitante_sin_activar.email, :return_to => embed_login_path
    end
    assert_response :redirect
    assert_redirected_to embed_login_path

    m = ActionMailer::Base.deliveries.last
    assert_equal I18n.t('notifier.welcome', :name => Settings.site_name), m.subject
    assert_equal m.to[0],   visitante_sin_activar.email
    assert_match "Bienvenido/a a #{Settings.site_name}", m.body.to_s
  end


  test "should see login form" do
    return_to = new_news_comment_path(documents(:commentable_news))
    get :new, :return_to => return_to
    assert_response :success
    assert_template "new"
    assert_select 'form[action=?]', session_path do
      assert_select "input[type=email][name=email]"
      assert_select "input[type=password][name=password]"
    end
    assert_select "a[href=?]", new_password_reset_path
    assert_select "a[href=?]", twitter_session_path(:return_to => return_to) if Rails.application.secrets["twitter"]
    assert_select "a[href=?]", fb_session_path(:return_to => return_to) if Rails.application.secrets["facebook"]
  end

  test "redirect to root path if logged in as admin" do
    user = users("admin")
    post :create, {:email => user.email, :password => 'test'}
    assert_redirected_to admin_path
    # assert_equal I18n.t('session.Has_entrado', :name => user.name), flash[:notice]
  end

  ["periodista", "visitante"].each do |role|
    test "redirect to account_path if logged as #{role}" do
      user = users(role)
      post :create, {:email => user.email, :password => 'test'}
      assert_redirected_to account_path
    end
  end

  roles = ["comentador_oficial", "secretaria_interior", "jefe_de_gabinete", "jefe_de_prensa", "colaborador"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "redirect to admin_path if logged as #{role}" do
      user = users(role)
      post :create, {:email => user.email, :password => 'test'}
      assert_redirected_to admin_path
    end
  end

  test "redirect to account path if logged in as room manager" do
    user = users("room_manager")
    post :create, {:email => user.email, :password => 'test'}
    # Los room_manager van a sadmin/account
    assert_redirected_to sadmin_account_path
  end


  test "should log out" do
    login_as("admin")
    delete :destroy
    assert_redirected_to root_path
    assert_equal I18n.t('session.Has_salido', :name => users("admin").name), flash[:notice]
  end

  test "should redirect to specified url once logged in" do
    user = users("admin")
    post :create, {:return_to => new_news_comment_path(documents(:commentable_news)), :email => user.email, :password => 'test'}
    assert_redirected_to new_news_comment_path(documents(:commentable_news))
    # assert_equal I18n.t('session.Has_entrado', :name => user.name), flash[:notice]
  end

  test "should get mobile login form" do
    get :new, :format => 'floki', :locale => 'es'
    assert_response :success
    assert_template 'sessions/new'
    assert_select 'form[action=?]', session_url(:format => 'floki') do
      assert_select "input[type=email][name=email]"
      assert_select "input[type=password][name=password]"
    end
  end

  test "should login from mobile" do
    user = users("admin")
    post :create, :email => user.email, :password => 'test', :format => 'floki'
    assert_response :success
    assert_template 'sessions/success.floki'
  end

  test "should get auth_info" do
    get :auth_info, :format => 'json'
    assert_response :success
    assert_template 'sessions/auth_info.json'
  end

  test "should destroy session mobile" do
    login_as("admin")
    delete :destroy, :format => 'floki'
    assert_response :success
  end

end
