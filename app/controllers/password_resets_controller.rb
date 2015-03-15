class PasswordResetsController < ApplicationController

  def create
    return_to = {:error => request.referer || new_password_reset_path,
                 :ok => params[:return_to] || login_path}

    if params[:email].blank?
      flash[:notice] = t('session.Por_favor_email')
      redirect_to return_to[:error] and return
    end

    user = User.approved.find_by_email(params[:email])
    if user
      if user.is_twitter_user?
        flash[:notice] = t("session.usuario_twitter_sin_password", :site_name => Settings.site_name)
      elsif user.is_facebook_user?
        flash[:notice] = t("session.usuario_facebook_sin_password", :site_name => Settings.site_name)
      elsif user.is_googleplus_user?
        flash[:notice] = t("session.usuario_googleplus_sin_password", :site_name => Settings.site_name)
      else
        user.send_password_reset
        flash[:notice] = t('session.Password_enviado')
      end
      if !request.xhr?
        redirect_to return_to[:ok] and return
      else
        render :nothing => true
      end
    else
      user = User.pending.find_by_email(params[:email])
      if user
        flash[:error] = t('session.pendiente_aprobacion')
      else
        flash[:error] = t('session.No_hay_usuario')
      end
      redirect_to return_to[:error] and return
    end

  end

  def edit
    @user = User.find_by_password_reset_token(params[:id])
    unless @user
      redirect_to root_url, :notice => I18n.t('password_resets.edit.wrong_token') and return
    end
  end

  def update
    @user = User.find_by_password_reset_token!(params[:id])
    if params[:user][:password].blank?
      flash[:notice] = "password #{t('activerecord.errors.messages.blank')}"
      redirect_to :back and return
    end
    if @user.password_reset_sent_at < 2.hours.ago
      redirect_to new_password_reset_path, :alert => t('password_resets.update.reset_expired')
    elsif @user.update_attributes(user_params)
      redirect_to root_url, :notice => t('password_resets.update.reset_done')
    else
      render :action => "edit"
    end
  end

  private
  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

end
