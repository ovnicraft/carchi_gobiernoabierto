# Controlador para la administración de usuarios
class Admin::UsersController < Admin::BaseController
  before_filter :set_current_tab
  before_filter :super_user_required
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_user_tag_list_es]

  # Listado de usuarios, por tipos
  def index
    @sort_order = params[:sort] ||  "status"

    case @sort_order
    when "name"
      order = "tildes(lower(name))"
    when "email"
      order = "lower(email), tildes(lower(name))"
    when "type"
      order = "lower(users.type), tildes(lower(name))"
    when "group"
      order = "(CASE WHEN users.type='Journalist' THEN media ELSE organizations.name_es END), tildes(lower(name))"
    when "status"
      order = "(CASE status WHEN 'pendiente' THEN 0 WHEN 'aprobado' THEN 1 WHEN 'vetado' THEN 2 ELSE 3 end), tildes(lower(name))"
    end

    @t = params[:t] || 'User'

    if params[:q].present?
      finder = User
      conditions = ["lower(tildes(name || coalesce(last_names, '') || coalesce(telephone, '') || coalesce(email, '') || users.type || coalesce(media, '') || coalesce(organizations.name_es, '')))  like ? ", "%#{params[:q].tildes.downcase}%"]
    else
      finder = @t.constantize
      conditions = nil
    end

    @users = finder.where(conditions)
      .joins("LEFT OUTER JOIN organizations ON (organizations.id=users.department_id)")
      .paginate(:page => params[:page]).order(order)

    @sessions = SessionLog.joins(:user).where(["type=?", @t])
      .order("action_at DESC").limit(20)
  end

  # Formulario de nuevo usuario
  def new
    @user = (params[:t] || 'Admin').constantize.new(:email => params[:email])
  end

  # Búsqueda del usuario por email, para ofrecer el cambio de perfil si es que ya existe
  def search
    if params[:email]
      @user = User.find_by_email(params[:email])
      if @user
        render :action => "make_admin"
      else
        redirect_to :action => 'new', :email => params[:email], :t => params[:t]
      end
    end
  end

  # Creación de nuevo usuario
  def create
    @user = params[:user][:type].constantize.new(user_params)
    if @user.save
      flash[:notice] = "El usuario ha sido dado de alta!"
      #redirect_to admin_users_url(:t => @user.type)
      redirect_to admin_user_url(@user)
    else
      render :action => "new"
    end
  end

  # Vista de un usuario
  def show
    @subtab = params[:subtab] || "data"
    @user = User.find(params[:id])
    if @subtab.eql?('sessions')
      @sessions = @user.session_logs.order("action_at DESC").limit(20)
    elsif @subtab.eql?('comments')
      @comments = @user.comments
    elsif @subtab.eql?('bulletins')
      @copies = @user.bulletin_copies.where("sent_at IS NOT NUll")
        .paginate(:page => params[:page], :per_page => 10)
        .order("sent_at DESC")
    end
  end

  # Modificar un usuario
  def edit
    @user = User.find(params[:id])
    get_document_counters
  end

  # Actualizar un usuario
  def update
    if params[:submit_cancel]
      redirect_to admin_users_path
    else
      if params[:id].eql?('current')
        @user = current_user
      else
        @user = User.find(params[:id])
      end
      get_document_counters
      if params[:user][:type]
        # Tengo que hacer esto para que cambie el class de user y actualice bien el departamento
        @user.type= params[:user][:type]
        @user.save
        @user = User.find(params[:id])
      end

      if @user.update_attributes(user_params)
        flash[:notice] = 'El usuario se ha actualizado correctamente.'

        #redirect_to admin_users_url(:t => @user.type)
        redirect_to admin_user_url(:id => params[:id])
      else
        render :action => 'edit'
      end
    end
  end

  # Modificar password de un usuario
  def pwd_edit
    @user=User.find(params[:id])
  end

  # Actualizar password de un usuario
  def pwd_update
    @user=User.find(params[:id])
    if @user.update_attributes(:password=>params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
      flash[:notice] = "Contraseña modificada"
      redirect_to(params[:return_to].empty? ? admin_users_path : params[:return_to])
    else
      render :action => "pwd_edit"
    end
  end

  def destroy
    @user = User.find(params[:id])
    user_type = @user.type

    if @user.destroy
      flash[:notice] = "El usuario se ha borrado correctamente"
      redirect_to admin_users_url(:t => user_type) and return
    else
      flash[:error] = "No ha podido borrarse el usuario"
      redirect_to edit_admin_user_path(@user) and return
    end
  end

  # Auto complete para los tags de los políticos
  def auto_complete_for_user_tag_list
    auto_complete_for_tag_list(params[:user][:tag_list])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.nombre)}) %>"
    else
      render :nothing => true
    end
  end

  private
  def set_current_tab
    @current_tab = :users
  end

  def get_document_counters
    @documents_counter = Document.where("created_by = #{@user.id} OR updated_by = #{@user.id}").count
    @videos_counter = Photo.where("created_by = #{@user.id} OR updated_by = #{@user.id}").count
    @comments_counter = Comment.where("user_id = #{@user.id}").count
    @proposals_counter = Proposal.where("user_id = #{@user.id}").count
  end

  def user_params
    params.require(:user).permit(:name, :last_names, :telephone, :url, :email, :type, :photo, :department_id, 
      :public_role_es, :public_role_eu, :public_role_en, :gc_id, :description_es, 
      :description_eu, :description_en, :politician_has_agenda, :password, :password_confirmation, :status, :alerts_locale,
      :stream_flow_ids => [])
  end

end
