# Controlador para los comentarios de las News, Video, y Proposal
class CommentsController < ApplicationController
  skip_before_filter :http_authentication
  skip_before_action :verify_authenticity_token, only: [:create], if: -> {request.format.to_s.eql?('json')}

  before_filter :get_parent, :except => [:index, :photo, :report_abuse, :department]
  before_filter :login_required_for_comments, :except => [:index, :department, :list]
  
  # Listado de todos los comentarios
  def index
    if params[:news_id]
      news = News.find(params[:news_id])
      @comments = news.all_comments.approved.reorder("created_at DESC").limit(20)
      @feed_title = t('comments.feed_title', :name => news.title)
    else
      @comments = Comment.approved.reorder("created_at DESC").limit(20)
      @feed_title = t('comments.feed_title', :name => Settings.site_name)
    end
    respond_to :rss
    # respond_to do |format|
    #   #format.html
    #   format.rss { render :layout=>false}
    # end
  end

  def department
    @department = Department.find(params[:id])
    @feed_title = t('comments.feed_title', :name => @department.name)
    organization_ids = [@department.id] + @department.organization_ids
    # Se supone que si una noticia tiene comentarios es porque esta ya publicada y se muestra en irekia.
    # No sabemos si esta traducida, pero creo que es mejor mostrarlo de todas formas.
    # Por lo tanto, no ponemos condiciones en ninguno de estos campos.
    
    # Cogemos también los comentarios en clientes externos de este departamento
    client_ids = ExternalComments::Client.where({:organization_id => organization_ids}).map {|client| client.id}
    
    finder = if client_ids.present?
      Comment.in_organizations_and_clients(organization_ids, client_ids)
    else
      Comment.in_organizations(organization_ids)
    end
    @comments = finder.approved.reorder("created_at DESC").limit(20)
    render :action => "index.rss", :layout => false
  end

  # Crear un comentario
  def create
    if params[:data].present?
      json_params = JSON.parse(params[:data])
      # comment_params = {:body => json_params["comment_text"]}
      this_comment_params = {:body => json_params["comment_text"]}
    else
      this_comment_params = comment_params
    end  
    this_comment_params.merge!(:user_id => current_user.id) if logged_in?

    @comment = @parent.comments.new(this_comment_params)      
    @comment.request = request

    # @tracking_url = "/#{I18n.locale}/commented"
   
    respond_to do |format|
      if @parent.has_comments? && !@parent.comments_closed? && @comment.save
        format.html { 
          @msg = if @comment.spam?
            t('comments.sorry_marked_as_spam')
          elsif @comment.approved?
            t('comments.comentario_guardado')
          else
            t('comments.comment_pending')
          end
          if request.xhr?  
            render :partial => "comment_created", :layout => false
          else
            flash[:notice] = @msg
            # flash[:tracking] = @tracking_url
            redirect_to(@parent) 
          end
        }
        format.floki { render :action => 'create.json', :content_type => 'application/json', :layout => false }
      else
        if !@parent.has_comments? || @parent.comments_closed?
          @comment.errors.add(:base, I18n.t('comments.comentarios_cerrados'))
        end   
        format.html { 
          if request.xhr?  
            render :json => "<li class='info'><div class='alert alert-error'>#{([I18n.t('comments.no_enviado')]+@comment.errors.full_messages)}</div></li>".to_json, :status => :error  
          else
            flash[:error] = "#{([I18n.t('comments.no_enviado')]+@comment.errors.full_messages)}"
            redirect_to(@parent)
          end
          return
        }
        format.floki
      end
    end
  end

  # Eliminar un comentario
  def destroy
    @comment = @parent.comments.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.xml  { head :ok }
    end
  end
    
  # Marca un comentario como inadecuado. Actualmente esta funcionalidad está desactivada.
  def report_abuse
    @comment = Comment.find(params[:id])
    
    @comment.abuse_counter += 1
    if @comment.save
      respond_to do |format|
        format.html {
          flash[:notice] = t('comments.abuse_thank_you2')
          redirect_to @comment.parent
        }
        format.js {
          render :update do |page|
            page.replace_html "abuse_#{@comment.id}", "<span>#{t('comments.abuse_thank_you')}</span>"
          end
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = t('comments.abuse_unsaved')
          redirect_to @comment.parent
        }
        format.js {
          logger.info "El aviso no se ha guardado: #{@comment.errors.inspect}"
          render :nothing => true
        }
      end
    end    
  end
  
  def list
    finder = if @parent.respond_to?(:all_comments)
      @parent.all_comments
    else
      @parent.comments
    end
    @comments = finder.approved.reorder("created_at DESC").limit(20)
  end
  
  private
  # Los comentarios no son autónomos, deben ir asociados a algún contenido de la web, 
  # actualmente un Document, Proposal o Video. Este filtro (se llama desde <tt>before_filter</tt>)
  # determina el contenido al que pertenece o pertenecerá el comentario a partir del parámetro que
  # se pasa en la URL
  def get_parent
    if params[:news_id]
      @parent = Document.find(params[:news_id])
    elsif params[:event_id]
      @parent = Document.find(params[:event_id])
    elsif params[:proposal_id]
      @parent = Proposal.find(params[:proposal_id])
    elsif params[:video_id]
      @parent = Video.find(params[:video_id])
    elsif params[:debate_id]
      @parent = Debate.find(params[:debate_id])
    elsif params["externalcomments::item_id"]
      @parent = ExternalComments::Item.find(params["externalcomments::item_id"])
    elsif params[:format].eql?('floki') && params[:item_id]
      if params[:item_id].to_i.between?(Floki::FACTORS[:news], Floki::FACTORS[:proposal])
        # podría ser un Event, los eventos no tienen comentarios
        item_type = 'News'
      elsif params[:item_id].to_i.between?(Floki::FACTORS[:proposal], Floki::FACTORS[:vote])
        item_type = 'Proposal'
      end
      @parent = item_type.constantize.find(params[:item_id].to_i - Floki::FACTORS[item_type.downcase.to_sym])
    else
      flash[:error] = "La URL no es correcta"
      redirect_to request.env["HTTP_REFERER"].present? ? :back : root_path
    end
  end
  
  # Construye los breadcrumbs de cada acción de los comentarios
  def make_breadcrumbs
    # if @document
    #   @breadcrumbs_info = [[@document.title,  document_path(@document)]]
    #   if @comment && !@comment.new_record?
    #     @breadcrumbs_info << [@comment.body[0..20],  document_comment_path(@document, @comment)]
    #   end
    # else
    #   @breadcrumbs_info = []
    # end
    @breadcrumbs_info = []
  end
  
  # Filtro que asegura que el usuario está loggeado antes de comentar
  def login_required_for_comments
    if !logged_in?
      flash[:notice] = t('session.tienes_que_registrarte2', :what => Comment.model_name.human.pluralize)
      store_location
      redirect_to new_session_path
    elsif !can_create?("comments")
      if request.xhr?
        render :json => "<li class='info'><div class='alert alert-error'>#{([I18n.t('comments.no_enviado'), t('comments.no_tienes_permiso')].join(" "))}</div></li>".to_json, :status => :error 
        return false 
      else
        store_location
        flash[:notice] = t('no_tienes_permiso')
        redirect_to new_session_path
      end
    else
      return true
    end
  end

  def comment_params
    params.require(:comment).permit(:name, :body)
  end
  
end
