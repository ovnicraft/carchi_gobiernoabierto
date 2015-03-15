# Controlador para la gestión de ficheros adjuntos a News, Event y Page
class Sadmin::AttachmentsController < Sadmin::BaseController
  before_filter :get_attachable, :only => [:new, :create]
  before_filter :get_attachment_and_attachable_by_id, :only => [:edit, :update, :destroy]
  before_filter :access_to_attachments_required
  
  # Formulario de creación de nuevo fichero adjunto
  def new
    @attachment = @attachable.attachments.build
    @title = t('sadmin.create_what', :what => Attachment.model_name.human)
  end
  
  # Creación de nuevo fichero adjunto
  def create
    @attachment = @attachable.attachments.build({:attachable_type => params[:attachable_type], :attachable_id => params[:attachable_id]}.merge(attachment_params))
    if @attachment.save
      flash[:notice] = t('sadmin.guardado_correctamente', :article => Attachment.model_name.human.gender_article, :what => Attachment.model_name.human)  
      redirect_to sadmin_document_page_url(@attachable)
    else
      render :action => "new"
    end
  end
  
  # Modificación de los atributos de un fichero
  def edit
    #@attachment = Attachment.find(params[:id])
    @title = t('sadmin.modificar_what', :what => @attachment.class.model_name.human)
  end
  
  # Actualización de los atributos de un fichero
  def update
    #@attachment = Attachment.find(params[:id])
    if @attachment.update_attributes(attachment_params)
      flash[:notice] = t('sadmin.guardado_correctamente', :article => @attachment.class.model_name.human.gender_article, :what => @attachment.class.model_name.human)
      redirect_to sadmin_document_page_url(@attachment.attachable)
    else
      render :action => "edit"
    end    
  end
  
  # Eliminación de un fichero
  def destroy
    #@attachment = Attachment.find(params[:id])
    if @attachment.destroy
      flash[:notice] = t('sadmin.eliminado_correctamente', :article => @attachment.class.model_name.human.gender_article, :what => @attachment.class.model_name.human)
    else
      flash[:error] = t('sadmin.no_eliminado_correctamente', :article => @attachment.class.model_name.human.gender_article, :what => @attachment.class.model_name.human)
    end
    redirect_to sadmin_document_page_url(@attachment.attachable)
  end
  
  private
  # Los ficheros adjuntos siempre pertenecen a un News, Event o Page. 
  # Este filtro coge el "padre" a partir de los parámetros de la URL
  def get_attachable
    @attachable = params[:attachable_type].constantize.find(params[:attachable_id])
    if @attachable 
      @current_tab = @attachable.class.to_s.tableize.to_sym
    end
  end
  
  # Filtro para coger el documento y su padre
  def get_attachment_and_attachable_by_id
    @attachment = Attachment.find(params[:id])
    @attachable = @attachment.attachable
    
    @current_tab = @attachable.class.to_s.tableize.to_sym
  end
  
  # Filtro para comprobar que el usuario tiene permiso para gestionar documentos adjuntos.
  def access_to_attachments_required
    if @attachable.is_a?(News)
      has_access = logged_in? && can_edit?("news")
    elsif @attachable.is_a?(Event)
      has_access = logged_in? && can_access?("events")
    else # page
      has_access = logged_in? && is_admin?
    end
    unless (logged_in? && has_access)
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end    
    
  end  
  
  # Genera la URL correcta para este fichero en función del tipo de documento al que pertenece
  def sadmin_document_page_url(doc)
    if doc.is_a?(Event) 
      sadmin_event_path(doc) 
    elsif doc.is_a?(Page)
      admin_document_path(doc)           
    elsif doc.is_a?(Proposal)
      admin_proposal_url(doc)  
    elsif doc.is_a?(Debate)
      admin_debate_url(doc)  
    else
      sadmin_news_path(doc)
    end
  end

  def attachment_params
    params.require(:attachment).permit(:file, :show_in_es, :show_in_eu, :show_in_en)
  end

end
