require 'test_helper'

class PasswordResetsControllerTest < ActionController::TestCase
  test "should not send password reset if email is empty" do
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      post :create, :email => '', :locale => "es"
    end
    assert_redirected_to new_password_reset_path
    assert_equal I18n.translate('session.Por_favor_email'), flash[:notice]
  end

  test "should email forgotten password to approved user" do
    assert_difference 'ActionMailer::Base.deliveries.size', + 1 do
      post :create, :email => 'visitante@efaber.net'
    end

    m = ActionMailer::Base.deliveries.last
    assert_equal I18n.t('notifier.password_reset.subject', :site_name => Settings.site_name), m.subject
    assert_equal m.to[0], 'visitante@efaber.net'
    assert_match 'Para cambiar tu contraseña, pincha en el siguiente enlace', m.body.to_s
  end

  test "should not email forgotten password to pending user" do
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      post :create, :email => 'visitante_sin_activar@efaber.net', :locale => "eu"
    end
    assert_redirected_to new_password_reset_path
    assert_equal "Erabiltzaile hau aktibazioaren zai dago", flash[:error]
  end

  test "should not email forgotten password to unexistent user" do
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      post :create, :email => 'noexiste@efaber.net', :locale => "eu"
    end
    assert_redirected_to new_password_reset_path
    assert_equal "Ez dago email hau duen erabiltzailerik", flash[:error]
  end

  test "should not email forgotten password to facebook user" do
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      post :create, :email => 'facebookuser@example.com', :locale => "es"
    end
    assert_redirected_to login_path
    assert_equal I18n.translate('session.usuario_facebook_sin_password', :site_name => Settings.site_name), flash[:notice]
  end

  test "should not email forgotten password if email is empty" do
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      post :create, :email => '', :locale => "es"
    end
    assert_redirected_to new_password_reset_path
    assert_equal I18n.translate('session.Por_favor_email'), flash[:notice]
  end

  context "reset password" do
    setup do
      @user_with_password_token = users(:visitante)
      @user_with_password_token.send_password_reset
    end

    should "with correct token be able to edit password" do
      get :edit, :id => @user_with_password_token.password_reset_token
      assert_response :success
      assert_template :edit
    end

    should "with incorrect token not be able to edit password" do
      get :edit, :id => "wrong-token"
      assert_redirected_to root_url
      assert_response :redirect
      assert_match I18n.t('password_resets.edit.wrong_token'), flash[:notice]
    end

    should "be able to update password" do
      put :update, :id => @user_with_password_token.password_reset_token, :user => {:password => 'secret', :password_confirmation => 'secret'}
      assert_match I18n.t('password_resets.update.reset_done'), flash[:notice]
      @user_with_password_token.reload
      assert_equal @user_with_password_token.crypted_password, User.encrypt('secret', @user_with_password_token.salt)
    end

    context "expired token" do
      setup do
        @user_with_password_token.update_attribute(:password_reset_sent_at, 5.hours.ago)
      end

      should "not be able to update password" do
        put :update, :id => @user_with_password_token.password_reset_token, :user => {:password => 'secret', :password_confirmation => 'secret'}
        assert_match I18n.t('password_resets.update.reset_expired'), flash[:alert]
        @user_with_password_token.reload
        assert_not_equal @user_with_password_token.crypted_password, User.encrypt('secret', @user_with_password_token.salt)
      end

    end
  end


  context "embed password reset" do
    setup do
      @request.env["HTTP_REFERER"] = password_reset_embed_session_path()
    end

    should "email forgotten password to approved user" do
      assert_difference 'ActionMailer::Base.deliveries.size', + 1 do
        post :create, :email => 'visitante@efaber.net', :return_to => embed_login_path()
      end

      m = ActionMailer::Base.deliveries.last
      assert_equal I18n.t('notifier.password_reset.subject', :site_name => Settings.site_name), m.subject
      assert_equal m.to[0], 'visitante@efaber.net'
      assert_match 'Para cambiar tu contraseña, pincha en el siguiente enlace', m.body.to_s
      assert_redirected_to embed_login_path
      assert_equal I18n.translate('session.Password_enviado'), flash[:notice]
    end

    should "not email forgotten password to pending user" do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        post :create, :email => 'visitante_sin_activar@efaber.net', :return_to => embed_login_path()
      end
      assert_redirected_to password_reset_embed_session_path
      assert_equal I18n.translate('session.pendiente_aprobacion'), flash[:error]
    end

    should "not email forgotten password to unexistent user" do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        post :create, :email => 'noexiste@efaber.net', :return_to => embed_login_path()
      end
      assert_redirected_to password_reset_embed_session_path
      assert_equal I18n.translate('session.No_hay_usuario'), flash[:error]
    end

    should "not email forgotten password to facebook user" do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        post :create, :email => 'facebookuser@example.com', :locale => "es", :return_to => embed_login_path()
      end
      assert_redirected_to embed_login_path
      assert_equal I18n.translate('session.usuario_facebook_sin_password', :site_name => Settings.site_name), flash[:notice]
    end

    should "not email forgotten password if email is empty" do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        post :create, :email => '', :locale => "es"
      end
      assert_redirected_to password_reset_embed_session_path
      assert_equal I18n.translate('session.Por_favor_email'), flash[:notice]
    end

  end
end
