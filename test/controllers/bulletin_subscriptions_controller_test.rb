require 'test_helper'

class BulletinSubscriptionsControllerTest < ActionController::TestCase
  context "with valid user_id" do
    setup do
      @user = users(:visitante)
      @encoded_user_id = @user.id.to_s(35)
    end

    context "with unsubscribed user" do
      should "not be subscribed" do
        assert !@user.wants_bulletin?
      end

      should "subscribe automatically" do
        get :new, :id => @encoded_user_id, :locale => 'eu'
        assert @user.reload.wants_bulletin?
        assert @user.reload.alerts_locale.eql?('eu')
        assert_template 'new'
        assert_select 'div.confirmation', I18n.t('bulletin_subscriptions.subscription_done')
      end

      should "not be able to unsubscribe" do
        get :edit, :id => @encoded_user_id
        assert_template 'edit'
        assert_select 'div.confirmation', I18n.t('bulletin_subscriptions.you_are_not_subscribed')
      end
    end

    context "with already subscribed user" do
      setup do
        @user.update_attribute(:wants_bulletin, true)
      end

      should "show already subscribed message" do
        get :new, :id => @encoded_user_id, :locale => 'eu'
        assert @user.reload.wants_bulletin?
        assert_template 'new'
        assert_select 'div.confirmation', I18n.t('bulletin_subscriptions.already_subscribed')
      end

      should "be able to unsubscribe" do
        get :edit, :id => @encoded_user_id, :locale => 'eu'
        assert_template 'edit'
        assert_select 'div.confirmation form[action=?]', bulletin_subscription_path(:id => @encoded_user_id)
      end

      should "unsubscribe" do
        post :destroy, :id => @encoded_user_id, :method => 'delete'
        assert !@user.reload.wants_bulletin?
        assert_template 'destroy'
        assert_select 'div.confirmation', I18n.t('bulletin_subscriptions.unsubscription_done')
      end
    end
  end
end
