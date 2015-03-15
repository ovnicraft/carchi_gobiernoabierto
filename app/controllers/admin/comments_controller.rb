# Controlador para la administración de comentarios
class Admin::CommentsController < Sadmin::BaseController
  before_filter :access_to_comments_required
  before_filter :comment_edit_required, :only => [:show, :update_status, :reject, :do_reject]
  before_filter :admin_required, :only => [:edit, :update, :destroy, :update_comments_status]
  # before_filter :set_conditions
  before_filter :maybe_restrict_to_user_department # sets @department_tag_id and @subtab_title
  before_filter :status_and_official_conditions, :only => [:index, :comments_on_item]
  before_filter :get_comment, :only => [:show, :edit, :update, :reject, :do_reject, :update_status, :destroy]

  before_filter :set_comments_finder
  before_filter :set_commentable_type, :only => [:comments_on_item, :update_comments_status]

  # Listado de comentarios en Irekia
  def index
    @subtab_title ||= 'Todos los comentarios'

    if @department_tag_id.nil?
      @comments = @comments_finder.joins("INNER JOIN users ON (users.id = comments.user_id) ")
        .where(@additional_conditions).paginate(:per_page => 20, :page => params[:page]).reorder("comments.created_at DESC")
    else
      @comments = @comments_finder.where(@additional_conditions).reorder("created_at DESC").paginate_by_sql(query_for_department(@department_tag_id, @additional_conditions),
        :page => params[:page], :per_page => 20)
    end
  end

  # Modificación de comentarios
  def edit
  end

  # Pantalla de confirmación de rechazo un comentario
  def reject
  end

  # Rechazar un comentario
  def do_reject
    @comment.send_reject_email = params[:reject_and_mail] ? true : false
    if @comment.reject!
      redirect_to(params[:return_to].present? ? params[:return_to] :  admin_comments_path)
    else
      render :action => :reject
    end
  end

  # Actualización de un comentario
  def update
    if @comment.update_attributes(comment_params)
      redirect_to(params[:return_to].present? ? params[:return_to] :  admin_comments_path)
    else
      render :action => :edit
    end
  end

  def update_status
    @comment.send("#{params[:do_action]}!") if params[:do_action]
    respond_to do |format|
      format.js
    end
  end

  # Eliminación de un comentario
  def destroy
    if @comment.destroy
      respond_to do |format|
        format.html {
          flash[:notice] = 'El comentario ha sido eliminado'
          redirect_to admin_comments_path
        }
        format.js
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = 'El comentario no ha podido ser eliminado'
          redirect_to admin_comments_path
        }
        format.js
      end

    end
  end

  # Muestra los comentarios de un contenido concreto
  def comments_on_item
    @item = @commentable_type.constantize.find(params[:id])
    if @department_tag_id && !@item.tag_ids.include?(@department_tag_id)
      flash[:notice] = t('no_tienes_permiso')
      redirect_to admin_comments_path
    end

    # @additional_conditions =  nil if @additional_conditions[0].blank?

    if @department_tag_id.nil?
      @comments = @item.comments.where(@additional_conditions).joins("INNER JOIN users ON (users.id = comments.user_id) ")
          .paginate(:per_page => 20, :page => params[:page]).reorder("created_at DESC")
    else
      @additional_conditions[0] << " AND commentable_id=#{@item.id}"
      @comments = @item.comments.paginate_by_sql(query_for_department(@department_tag_id, @additional_conditions),
        :page => params[:page], :per_page => 20, :order => "created_at DESC")
    end

    @title = "Comentarios en #{@item.class.model_name.human} \"#{@item.title_es}\""
    rewrite_current_tab
  end

  # Actualiza el campo de si un contenido admite comentarios o no
  def update_comments_status
    # , :readonly => false
    @item = @commentable_type.constantize.find(params[:item_id])
    if @department_tag_id && !@item.tag_ids.include?(@department_tag_id)
      flash[:notice] = t('no_tienes_permiso')
    else
      @item.update_attribute(:comments_closed, params[:comments_closed])
    end
    redirect_to comments_on_item_admin_comment_path(@item, :type => @commentable_type)
  end

  private
  # Determina el tab de la administración que estará activo
  def set_current_tab
    @current_tab = :comments
  end

  # Sobreescribe el tab activo de la administración
  def rewrite_current_tab
    @t = @item ? @item.class.to_s.downcase.pluralize : (params[:t].present? ? params[:t] : 'news')

    @current_tab = @t.to_sym
    @current_tab
  end

  def query_for_department(department_tag_id, additional_conditions="")
    query = "SELECT comments.id, coalesce(document_id, video_id) AS commentable_id, commentable_type,
        comments.status, body, comments.name, user_id, comments.email, comments.created_at
      FROM (SELECT comments.*, documents.id AS document_id, videos.id as video_id FROM comments
        LEFT OUTER JOIN documents ON (documents.id=comments.commentable_id AND commentable_type='Document')
        LEFT OUTER JOIN videos ON (videos.id=comments.commentable_id AND commentable_type='Video')) as comments, taggings, users
        WHERE users.id = comments.user_id
          AND coalesce(document_id, video_id)= taggings.taggable_id AND comments.commentable_type=taggings.taggable_type
          AND taggings.tag_id=#{department_tag_id} AND #{additional_conditions[0]}
        ORDER BY comments.created_at DESC"
    [query, additional_conditions[1]]
  end

  def comment_edit_required
    unless (logged_in? && can_edit?("comments"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def get_comment
    @comment = Comment.find(params[:comment_id] || params[:id])
    if @department_tag_id && !@comment.commentable.tag_ids.include?(@department_tag_id)
      respond_to do |format|
        format.html do
          flash[:notice] = t('no_tienes_permiso')
          access_denied
        end
        format.js do
          flash[:notice] = t('no_tienes_permiso')
          render '/admin/comments/not_found.js.erb'
        end
      end
    end
  end

  def maybe_restrict_to_user_department
    if current_user.respond_to?(:department) && current_user.department.present?
      @department = Department.find(current_user.department_id)
      @department_tag_id = ActsAsTaggableOn::Tag.find_by_name_es(@department.tag_name).id
      @subtab_title = "Comentarios del departamento #{current_user.department.name}"
    elsif params[:dep_id] && params[:dep_id].to_i != 0
      @department = Department.find(params[:dep_id])
      @department_tag_id = ActsAsTaggableOn::Tag.find_by_name_es(@department.tag_name).id
      @subtab_title = "Comentarios del departamento #{@department.name}"
    end
  end

  def status_and_official_conditions
    # @additional_conditions = []
    # if @status = params[:status]
    #   @additional_conditions << "where('comments.status ilike ?', #{status})"
    # end
    # if @oficiales = (params[:oficiales] && params[:oficiales].to_i == 1) || false
    #   @additional_conditions << "where('comments.is_official ilike ?', true)"
    # end
    # @additional_conditions = @additional_conditions.present? ? @additional_conditions.join('.') : 'all'

    @additional_conditions = ["1=1", {}]
    @status = params[:status]
    if @status
      @additional_conditions[0] << " AND comments.status=:status"
      @additional_conditions[1][:status] = @status
    end

    @oficiales = (params[:oficiales] && params[:oficiales].to_i == 1) || false
    if @oficiales
      @additional_conditions[0] << " AND comments.is_official='t'"
    end
  end

  def set_comments_finder
    @comments_finder = Comment.local
  end

  def set_commentable_type
    @commentable_type = params[:type]
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
