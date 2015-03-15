# Controlador par la administración de propuestas ciudadanas
class Admin::ProposalsController < Admin::BaseController
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_proposal_tag_list]
  skip_before_filter :admin_required

  before_filter :proposal_view_info_required, :only => [:index, :arguments]
  before_filter :proposal_edit_info_required, :only => [:show, :edit, :edit_common, :update, :publish, :reject, :do_reject]
  before_filter :proposal_create_info_required, :only => [:new, :create, :destroy, :comments]

  before_filter :get_proposal, :only => [:show, :edit, :edit_common, :update, :comments, \
                                         :update_status, :publish, :comments, :destroy, :reject, :do_reject]

  uses_tiny_mce :only => [:new, :create, :edit, :edit_common, :update],
                :options => TINYMCE_OPTIONS


  def index
    @title = t("admin.proposals.peticiones")

    @sort_order = params[:sort] ||  "update"

    case @sort_order
    when "update"
      order = "updated_at DESC, title_es, published_at DESC"
    when "publish"
      order = "created_at DESC, title_es, updated_at DESC"
    when "title"
      order = "lower(tildes(title_es)), published_at DESC, updated_at DESC"
    end

    conditions = []
    cond_values = {}

    # # Escondemos las propuestas traspasadas a debate.
    # conditions = ["proposals.status not like :exclude_status"]
    # cond_values = {:exclude_status => "traspasado%"}

    if params[:q].present?
      conditions << "lower(tildes(coalesce(title_es, '') || ' ' || coalesce(title_eu, ''))) like :q"
      cond_values[:q] = "%" + params[:q].tildes.downcase + "%"
    end

    if current_user.respond_to?(:department) && current_user.department.present?
      department = current_user.department
      conditions << "organization_id = :dep_id"
      cond_values[:dep_id] = department.id
      @title = "Peticiones para el departamento #{department.name}"
    end

    # .joins(" INNER JOIN users ON (user_id=users.id) AND users.status='aprobado'")
    @proposals = Proposal.joins(:user).where([conditions.join(' AND '), cond_values]).paginate(:page => params[:page], :per_page => 20)
          .reorder(order)

    # @your_proposals_text = Proposal.yours_intro_page
    # @our_proposals_text = Proposal.ours_intro_page
  end

  def show
    @title = "#{@proposal.title}"
  end

  def arguments
     @arguments = Argument.for_proposals.joins("INNER JOIN users ON (users.id = arguments.user_id) ")
        .paginate(:per_page => 20, :page => params[:page]).reorder("published_at DESC, created_at DESC")
  end

  def edit
    @title = "Modificar propuesta"
  end

  def update
    @proposal.attributes = proposal_params

    @title = "Actualizar propuesta"

    if @proposal.save
      flash[:notice] = 'El propuesta se ha guardado correctamente'

      send_notifications

      redirect_to admin_proposal_path(@proposal)
    else
      render :action => params[:return_to] || 'edit'
    end
  end

  def destroy
    @title = 'Eliminar propuesta'
    @proposal.destroy
    respond_to do |format|
      format.html do
        if @proposal.destroyed?
          flash[:notice] = 'La propuesta se ha eliminado correctamente'
        else
          flash[:error] = 'La propuesta no se ha podido eliminar'
        end
        redirect_to admin_proposals_path
      end
      format.js
    end
  end

  def comments
    @comments = @proposal.comments.paginate(:per_page => 20, :page => params[:page]).reorder("created_at DESC")
    @title = "Comentarios de la propuesta \"#{@proposal.title_es}\""
  end

  def publish
    @proposal.update_attributes(:published_at => Time.zone.now)
    redirect_to @proposal
  end

  def update_status
    if @proposal.update_attributes(proposal_status_params)
      send_notifications
    else
      render :status => 422
    end
  end

  def reject
    params[:return_to] = request.referer
  end

  # Rechacar un comentario
  def do_reject
    @proposal.send_reject_email = params[:reject_and_mail] ? true : false
    if @proposal.reject!
      redirect_to(params[:return_to].present? ? params[:return_to] :  admin_comments_path)
    else
      render :action => :reject
    end
    # if @proposal.update_attributes(:status => "rechazado")
    #   if params[:reject_and_mail]
    #     begin
    #       logger.info("Mandando email sobre comentario rechazado a #{@proposal.user.email}")
    #       Notifier.proposal_rejection(@proposal).deliver
    #       flash[:notice] = "El email ha sido enviado"
    #     rescue Net::SMTPServerBusy, Net::SMTPSyntaxError => err_type
    #       logger.info("Error al mandar el email: " + err_type)
    #       flash[:error] = t('session.Error_servidor_correo')
    #     end
    #   end
    #   redirect_to(params[:return_to].present? ? params[:return_to] :  admin_proposals_path)
    # else
    #   render :action => :reject
    # end
  end

  def auto_complete_for_proposal_tag_list
    auto_complete_for_tag_list_first_beginning_then_the_rest(params[:proposal][:tag_list])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.name)}.join.html_safe) %>"
    else
      render :nothing => true
    end
  end

  private

  def set_current_tab
    @current_tab = :proposals
  end

  def get_proposal
    @proposal = Proposal.find(params[:id])
  end

  def proposal_view_info_required
    unless (logged_in? && (can_edit?("proposals") || can?("official", "comments")))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def proposal_edit_info_required
    unless (logged_in? && can_edit?("proposals"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def proposal_create_info_required
    unless (logged_in? && can_create?("proposals"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def send_notifications
    if @proposal.notify_department
      Notifier.proposal_organization(@proposal).deliver
    end

    if @proposal.user.email.present? && @proposal.notify_proposer
      Notifier.proposal_approval(@proposal).deliver
    end
  end

  def proposal_params
    params.require(:proposal).permit(:title_es, :title_eu, :title_en, :body_es, :body_eu, :body_en, 
      :organization_id, :featured, :comments_closed, :image, :remove_image, :tag_list, :draft, 
      :published_at, :status)
  end

  def proposal_status_params
    params.require(:proposal).permit(:status)
  end

end
