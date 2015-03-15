require 'test_helper'

class PeopleControllerTest < ActionController::TestCase

  test "should get intro page" do
    get :intro, :locale => 'es'
    assert_response :success
  end

  test "should get new html" do
    @request.env["HTTP_REFERER"] = news_index_url()

    get :new, :locale => 'es'
    assert_response :success
    assert_template 'people/new', layout: "layouts/application"

    assert_equal news_index_url, session[:return_to]
  end

  test "should get new xhr" do
    xhr :get, :new, :locale => 'es'
    assert_response :success
    assert_template layout: nil
  end

  test "should post create with errors" do
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'Person.count' do
        post :create, :user => {:email => 'prueba@email.com', :password => '123456', :password_confirmation => '123456',
          :normas_de_uso => '1'}
      end
    end
    assert_response :success
    assert_template 'people/new'
  end

  test "should post create ok" do
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      assert_difference 'Person.count', +1 do
        post :create, :user => {:email => 'prueba@email.com', :password => '123456', :password_confirmation => '123456',
          :normas_de_uso => '1', :name => "Nuevo usuario", :zip => "48900"}
      end
    end
    assert_response :success
    assert_template 'people/create'
    # assert_select "a", :text => I18n.translate('people.create.volver_navegar')
    assert assigns(:user).status == 'pendiente'

    welcome_email = ActionMailer::Base.deliveries.last
    assert_equal I18n.t('notifier.welcome', :name => Settings.site_name), welcome_email.subject
    assert_equal welcome_email.to[0], 'prueba@email.com'
    assert_match 'Para asegurarnos de que realmente has solicitado el alta en', welcome_email.body.to_s
  end

  context "from embed login" do
    should "show new with embed layout" do
      @request.env["HTTP_REFERER"] = embed_login_url()

      get :new, :locale => 'es'
      assert_response :success
      assert_template 'people/new', layout: "layouts/embed"

      assert_equal embed_login_url, session[:return_to]
    end

    should "show new with embed layout after error in create" do
      session[:return_to] = embed_login_path()

      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        assert_no_difference 'Person.count' do
          post :create, :user => {:email => 'prueba@email.com', :password => '123456', :password_confirmation => '123456',
            :normas_de_uso => '1'}
        end
      end
      assert_response :success
      assert_template 'people/new', layout: "layouts/embed"

      assert_equal embed_login_path(), session[:return_to]
    end

    should "create new person" do
      session[:return_to] = embed_login_path()

      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        assert_difference 'Person.count', 1 do
          post :create, :user => {:email => 'prueba@email.com', :password => '123456', :password_confirmation => '123456',
            :normas_de_uso => '1', :name => "Nuevo usuario", :zip => "48900"}
        end
      end
      assert_response :success
      assert_template 'people/create', layout: "layouts/embed"

      assert_select "a", :text => I18n.translate('people.create.volver_al_login', :site_name => Settings.site_name)

      assert assigns(:user).status == 'pendiente'

      welcome_email = ActionMailer::Base.deliveries.last
      assert_equal I18n.t('notifier.welcome', :name => Settings.site_name), welcome_email.subject
      assert_equal welcome_email.to[0], 'prueba@email.com'
      assert_match 'Para asegurarnos de que realmente has solicitado el alta en', welcome_email.body.to_s
    end

  end

end
