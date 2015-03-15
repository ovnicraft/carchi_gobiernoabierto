class BulletinSubscriptionsController < ApplicationController
  before_filter :get_user, :except => [:index, :create]
  before_filter :login_required, :only => [:create]

  def index
    @return_to = store_session_return_to
    if request.xhr?
      render :json => true and return
    end
  end

  def new # should be create but we are allowing direct subscription through link in email
    update_user_wants_bulletin
  end

  def create
    @user = current_user
    update_user_wants_bulletin
    if @user.email.blank? && @user.bulletin_email.blank?
      redirect_to edit_account_path(:subscription => '1') and return
    else
      render :action => 'new'
    end
  end

  def destroy
    if params[:cancel]
      @status = 'canceled'
    else
      if @user.update_attributes(:wants_bulletin => false)
        @status = 'unsubscribed'
      else
        @status = 'failed'
      end
    end
  end

  private
  def get_user
    begin
      @user = User.find(params[:id].to_i(35))
    rescue
      render :text => I18n.t('bulletin_subscriptions.invalid_subscription') and return
    end
  end

  def make_breadcrumbs
    @breadcrumbs_info = [[t('bulletin_subscriptions.alta_en_el_boletin'), bulletin_subscriptions_path]]
  end

  def update_user_wants_bulletin
    if @user.wants_bulletin
      @status = 'already_subscribed'
    else
      if @user.update_attributes(:wants_bulletin => true, :alerts_locale => params[:locale] || I18n.locale.to_s)
        @status = 'subscribed'
      else
        @status = 'failed'
      end
    end
  end
end
