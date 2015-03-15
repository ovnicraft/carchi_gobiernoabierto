# Controlador para las opciones de configuracion de la cuenta de los usuarios registrados
class AccountController < ApplicationController
  before_filter :login_required, :except => [:activate, :activity]
  before_filter :maybe_redirect_to_user_settings, :only => [:edit]
  before_filter :maybe_redirect_to_user_sadmin_account, :only => [:show]
  before_filter :login_required_for_activity, :only => :activity
  before_filter :outside_user_forbidden, :only => [:pwd_edit, :pwd_update]
  before_filter :get_current_user_and_followings, :only => [:show, :questions, :proposals, :activity, :followings]

  attr_accessor :old_password

  # La cuenta del usuario loggeado
  def show
    get_activity
    @items = (@my_precontent + @precontent).flatten.uniq.sort {|a,b| b.published_at.to_i <=> a.published_at.to_i}[0..19]
  end

  # Modificar los datos personales del usuario loggeado
  def edit
    @user = current_user
    if params[:subscription].eql?('1')
      @subscription = true
      flash[:notice] = t('bulletin_subscriptions.email_needed')
    end
    @title = t('account.your_profile')
    @breadcrumbs_info = [[t('account.your_profile'), edit_account_path]]
  end

  # Actualizar los datos personales del usuario loggeado
  def update
    @user = User.find(current_user.id)

    if params[:cancel]
      flash[:notice] = 'Update cancelado'
      redirect_to account_path
    else
      if @user.update_attributes(user_params)
        if params[:subscription_attributes].eql?('1')
          flash[:notice] = t('bulletin_subscriptions.subscription_done')
        else
          flash[:notice] = t('account.datos_guardados')
        end
        redirect_to account_path
      else
        render :action => 'edit'
      end
    end
  end

  # Modificar la contraseña del usuario loggeado
  def pwd_edit
    @user = User.find(current_user.id)
    @title = t('account.cambiando_contrasena')
    @breadcrumbs_info = [[t('account.mi_cuenta'), account_path], [t('account.cambiando_contrasena'), pwd_edit_account_path]]
    render :action => "pwd_edit"
  end

  # Actualizar la contraseña del usuario loggeado
  def pwd_update
    @user = User.find(current_user.id)
    if @user.update_attributes(params[:user])
      flash[:notice] = t('account.datos_guardados')
      redirect_to account_path
    else
      render :action => 'pwd_edit'
    end
  end

  # Confirmación de la baja del sistema del usuario loggeado
  def confirm_delete
    @title = t('account.confirm_delete_account_title')
    render :action => "confirm_delete"
  end

  # Desactivar la cuenta del usuario loggeado
  def destroy
    if params[:cancel]
      flash[:notice] = t('account.cuenta_no_eliminada', :email => Settings.email_addresses[:contact])
      redirect_to account_path
    else
      @user = User.find(current_user.id)
      if @user.deactivate_account
        self.current_user.forget_me if logged_in?
        cookies.delete :auth_token
        reset_session
        flash[:notice] = t('account.cuenta_eliminada')
        redirect_to root_path
      else
        flash[:error] = t('account.cuenta_no_eliminada_razon')
        redirect_to account_path
      end
    end
  end


  def image
    uploader = ImageUploader.cache_from_io!(request.body, params.delete(:qqfile))
    @image = {
      :success => true,
      :image_cache_name => uploader.cache_name
    }
    render :text => @image.to_json and return
  end

  def photo
    uploader = PhotoUploader.cache_from_io!(request.body, params.delete(:qqfile))
    @photo = {
      :success => true,
      :photo_cache_name => uploader.cache_name
    }
    render :text => @photo.to_json and return
  end

  # Activación de la cuenta de un usuario registrado
  def activate
    @title = "Activar cuenta"
    @user = Person.where(["id= ? AND crypted_password = ? AND status IN ('pendiente', 'aprobado')", params[:u].to_i, params[:p]]).first
    if @user.present?
      @user.update_attribute(:status, "aprobado")
      self.current_user = @user
      @success = true
    else
      success = false
    end
  end

  def questions
    # Tus preguntas
    @answered_questions_count = current_user.questions.approved.published.answered.count
    @user = current_user

    per_page = request.xhr? ? 5 : 20
    order = params[:more_polemic] ? "comments_count DESC" : "published_at DESC"

    if params[:answered]
      @questions = @user.questions.published.answered.paginate :order => order,
        :per_page => per_page, :page => params[:page]
    else
      @questions = @user.questions.published.paginate :order => order,
        :per_page => per_page, :page => params[:page]
    end

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => '/questions/questions_or_none', :layout => false
        else
          render
        end
      end
      format.floki do
        render :template => "/mob_app/questions.json", :layout => false, :content_type => "application/json"
      end
    end
  end

  def proposals
    @user = current_user

    per_page = request.xhr? ? 5 : 20
    order = params[:more_polemic] ? "comments_count DESC" : "proposals.published_at DESC"

    @proposals = current_user.proposals.paginate(:per_page => per_page, :page => params[:page]).order(order)

    @approved_by_majority = Proposal.find_by_sql(["SELECT proposals.id, sum(value) as sum
      FROM proposals INNER JOIN votes ON (votes.votable_id = proposals.id AND votes.votable_type = 'Proposal')
      WHERE (((((proposals.published_at <= ?)) AND (proposals.status='aprobado'))
        AND (proposals.user_id = #{current_user.id})))
      group by proposals.id
      having sum(value)>0", Time.zone.now]).length

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => '/shared/list_items', :locals => {:items => @proposals, :type => 'proposals'}, :layout => false
        else
          render
        end
      end
      format.floki do
        render :template => "/mob_app/proposals.json", :layout => false, :content_type => "application/json"
      end
    end
  end

  def activity
    get_activity
    respond_to do |format|
      format.html do
        @content = (@my_precontent + @precontent).flatten.uniq.sort {|a,b| b.published_at.to_i <=> a.published_at.to_i}[0..19]
        render
      end
      format.floki do
        @my_content = @my_precontent.flatten.sort {|a,b| b.published_at.to_i <=> a.published_at.to_i}
        @content = (@precontent.flatten - @my_content).sort {|a,b| b.published_at.to_i <=> a.published_at.to_i}[0..19]
        render :action => 'activity.json', :layout => false
      end
    end
  end

  def followings
  end

  def notifications
    @notifications = current_user.notifications.pending.order("created_at")
    @title = Notification.model_name.human(:count => 2).capitalize
  end

  private
  def outside_user_forbidden
    if current_user.is_outside_user?
      flash[:notice] = I18n.t('no_tienes_permiso')
      redirect_to account_path
    end
  end

  def login_required_for_activity
    if !logged_in?
      respond_to do |format|
        format.html {access_denied}
        format.floki {render :action => 'login_required.floki', :layout => false, :content_type => "application/json"}
      end
    end
  end

  def get_activity
    @my_precontent = []

    if current_user.is_a?(Politician)
    else
      # reacciones a mis propuestas y propuestas en los últimos 3 días

      days_ago = 3.days.ago
      # Comentarios en mis propuestas y preguntas
      @my_precontent << Comment.approved
        .select("comments.id, commentable_id, commentable_type, body, comments.created_at,comments.status, comments.user_id, comments.name, comments.email, comments.is_official")
        .joins("INNER JOIN proposals on (proposals.id=comments.commentable_id and commentable_type='Proposal')")
        .where(["proposals.user_id=#{current_user.id} AND comments.created_at >=?", days_ago])
        .order("comments.created_at DESC")

      # Votos en mis propuestas
      @my_precontent << Vote
        .select("votes.id, value, votable_id, votable_type, votes.created_at, votes.user_id, proposals.title_#{I18n.locale} AS proposal_title")
        .joins("INNER JOIN proposals on (proposals.id=votes.votable_id and votable_type='Proposal')")
        .where(["proposals.user_id=#{current_user.id} AND votes.created_at >=?", days_ago])
        .order("votes.created_at DESC")

      # Argumentos en mis propuestas
      @my_precontent << Argument.published
        .select("arguments.id, reason, arguments.published_at, arguments.created_at, argumentable_id, argumentable_type, arguments.user_id, arguments.value")
        .joins("INNER JOIN proposals on (proposals.id=arguments.argumentable_id and argumentable_type='Proposal')")
        .where(["proposals.user_id=#{current_user.id} AND arguments.created_at >=?", days_ago])
        .order("arguments.published_at DESC")
    end

    # Noticias de las áreas a las que sigue
    @precontent = []
    if current_user.following_areas.length > 0
      @precontent << News.published.translated.tagged_with(current_user.following_areas.collect(&:area_tag))
        .select("documents.id, title_#{I18n.locale}, published_at, has_comments, multimedia_path, cover_photo_file_name, body_es, body_eu, body_en, comments_closed, consejo_news_id")
        .order('published_at DESC').limit(20)

      @precontent << Event.published.translated.tagged_with(current_user.following_areas.collect(&:area_tag))
        .select("documents.id, title_es, title_eu, title_en, stream_flow_id, streaming_for, irekia_coverage, irekia_coverage_audio, 
                    irekia_coverage_video, irekia_coverage_article, irekia_coverage_photo, streaming_live,
                    published_at, starts_at, ends_at, place, city, location_for_gmaps, body_es, body_eu, body_en")
        .order('published_at DESC').limit(20)

      @precontent << Proposal.approved.published.translated.tagged_with(current_user.following_areas.collect(&:area_tag))
        .select("proposals.id, title_es, title_eu, title_en,
                    substring(body_es from 0 for 500) as body_es,
                    substring(body_es from 0 for 500) as body_eu,
                    substring(body_es from 0 for 500) as body_en,
                    proposals.created_at, published_at, has_comments, comments_closed, status,
                    user_id")
        .order('published_at DESC').limit(20)

      # TODO: should albums and videos be included?
      # @precontent << Video.published.translated.tagged_with(current_user.following_areas.collect(&:area_tag))
      #   .select("videos.id, title_#{I18n.locale}, published_at, video_path, subtitles_es_file_name, subtitles_eu_file_name, subtitles_en_file_name")
      #   .order('published_at DESC').limit(20)

      # @precontent << Album.published.tagged_with(current_user.following_areas.collect(&:area_tag))
      #   .select("albums.id, title_#{I18n.locale}, albums.created_at")
      #   .order('created_at DESC').limit(20)

    end

  end

  def maybe_redirect_to_user_settings
    if current_user.has_admin_access?
      redirect_to admin_url
    else
      return true
    end
  end

  def maybe_redirect_to_user_sadmin_account
    if current_user.is_a?(Politician)
      redirect_to politician_url(current_user)
    elsif current_user.has_admin_access? && !current_user.is_admin?
      redirect_to sadmin_account_url
    else
      return true
    end
  end

  def get_current_user_and_followings
    @user = current_user
    @following_politicians = current_user.following_politicians
    @following_areas = current_user.following_areas
  end

  def make_breadcrumbs
    @breadcrumbs_info = []
    if params[:action].eql?('proposals')
      @breadcrumbs_info << [t("account.your_proposals"), proposals_account_path]
    # elsif params[:action].eql?('questions')
    #     @breadcrumbs_info << [t("account.your_questions"), questions_account_path]
    elsif params[:action].eql?('show')
      @breadcrumbs_info << [t("account.your_profile"), account_path]
    elsif params[:action].eql?('edit')
      @breadcrumbs_info << [t("account.edit_profile"), edit_account_path]
    elsif params[:action].eql?('followings')
      @breadcrumbs_info << [t("users.following"), followings_account_path]
    elsif params[:action].eql?('notifications')
      @breadcrumbs_info << [@title, notifications_account_path]
    end
  end

  def user_params
    if @user.is_a?(Journalist)
      params.require(:user).permit(:email, :password, :password_confirmation, :name, :last_names, :photo, :remove_photo, :subscription, :bulletin_email, :wants_bulletin, :alerts_locale, :normas_de_uso, :telephone, :media, :url, :subscriptions_attributes => [:department_id, :_destroy, :id])
    elsif @user.is_a?(Politician)
      params.require(:user).permit(:email, :password, :password_confirmation, :name, :last_names, :photo, :remove_photo, :subscription, :bulletin_email, :wants_bulletin, :alerts_locale, :normas_de_uso, :telephone, :attachments_attributes => [:file, :show_in_es, :show_in_eu, :show_in_en, :_destroy, :id])
    elsif @user.is_a?(Person)  
      params.require(:user).permit(:email, :password, :password_confirmation, :name, :last_names, :photo, :remove_photo, :subscription, :bulletin_email, :wants_bulletin, :alerts_locale, :normas_de_uso, :telephone, :zip)
    end
  end

end
