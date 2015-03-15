class Admin::External::ClientsController < Sadmin::BaseController
  before_filter :admin_required
  
  before_filter :set_title
  before_filter :get_client, :except => [:index, :new, :create]
  
  def index
    @sort_order = ["name", "code", "url", "organization_id"].include?(params[:sort]) ? params[:sort] : "name"
    
    if @sort_order.eql?("name")
      order = "tildes(lower(name))::text"
    else
      order = @sort_order
    end
    
    @clients = ExternalComments::Client.order(order)
  end
  
  def show
  end
  
  def edit
  end
  
  def create
    @client = ExternalComments::Client.new(client_params)
    if @client.save
      respond_to do |format|
        format.html {       
          flash[:notice] = "El cliente ha sido creado."
          redirect_to admin_external_client_path(@client)
        }
        format.js
      end    
    else
      render :action => "new"
    end
  end
  
  def update
    if @client.update_attributes(client_params)
      flash[:notice] = "El cliente ha sido modificado."
      redirect_to admin_external_client_path(@client)
    else
      render :action => "edit"
    end
  end

  def destroy
    if @client.commentable_items.count.eql?(0)
      @client.destroy
      flash[:notice] = t('admin.external.clients.eliminado')
      redirect_to admin_external_clients_path() and return
    else
      flash[:error] = t('admin.external.clients.no_eliminado')
      redirect_to admin_external_client_path(@client)
    end
  end
  
  private
  
  # Determina el tab de la administración que estará activo
  def set_current_tab
    @current_tab = :comments
  end


  # Título de la página. Es el mismo que el título para las demás pestañas dentro de Comentarios.
  def set_title
    @page_title ||= nil
  end
  
  def get_client
    @client = ExternalComments::Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :url, :code, :organization_id, :notes)
  end
end
