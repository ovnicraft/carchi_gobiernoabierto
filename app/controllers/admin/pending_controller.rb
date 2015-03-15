class Admin::PendingController < Admin::BaseController
  layout 'mobile.html.erb'
  before_filter :access_to_comments_required
  before_filter :admin_required
  before_filter :get_pending, :only => [:approve, :spam, :reject, :edit_proposal, :destroy]

  def index
    # comments, arguments, proposals
    # @pendings = (Comment.pending + Argument.pending + Proposal.pending).sort_by{|a| a.created_at}
    @pendings = (Comment.pending + Argument.pending + Proposal.pending).sort_by(&:created_at).reverse
  end

  def approve
    if @pending.approve!(pending_params)
      flash[:notice] = 'Item aprobado!'
    else
      flash[:error] = "Error al aprobar el item #{@pending.errors.full_messages}"
    end
    redirect_to admin_pending_path
  end

  def spam
    if @pending.mark_as_spam!
      flash[:notice] = 'Item marcado como spam'
    end
    redirect_to admin_pending_path
  end

  def reject
    @pending.send_reject_email = true if params[:send_reject_email]
    if @pending.reject!
      flash[:notice] = 'Item rechazado!'
    else
      flash[:error] = "Error al rechazar el item #{@pending.errors.full_messages}"
    end
    redirect_to admin_pending_path
  end

  def edit_proposal
  end

  def destroy
    if @pending.destroy
      flash[:notice] = 'Item eliminado!'
    end
    redirect_to admin_pending_path
  end

  private
  def get_pending
    @pending = params[:pending_type].classify.constantize.find(params[:pending_id])
  end

  def pending_params
    params.fetch(:pending, {}).permit(:organization_id)
  end

end