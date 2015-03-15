class Admin::ArgumentsController < Admin::BaseController
  def index
    @arguments = Argument.joins("INNER JOIN users ON (users.id = arguments.user_id) ").paginate(:per_page => 20, :page => params[:page]) 
      .reorder("published_at DESC, created_at DESC")
  end

  def show
  end
  
  def approve
    @argument = Argument.find(params[:id])
    @argument.approve!
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    @argument = Argument.find(params[:id])
    @argument.destroy
    respond_to do |format|
      format.html do 
        if @argument.destroyed?
          flash[:notice] = 'El argumento ha sido eliminado'
        else
          flash[:error] = 'El argumento no ha podido ser eliminado'
        end
        redirect_to admin_arguments_path
      end
      format.js
    end
  end
  
end
