# Incrustar comentarios
class Embed::CommentsController < Embed::BaseController
  
  # Comentarios sobre un external_comments_item definido por su URL y el cliente.
  # Se guarda también el título de la página donde se hace el comentario.
  def show
    get_client_and_item()
    # Allow everywhere
    # response.headers.delete('X-Frame-Options')
    if (@client && @item) 
      response.headers["X-Frame-Options"] = "ALLOW-FROM #{request.protocol}#{@client.url}"
      @comments = @item.all_comments.approved.paginate :page => params[:page] || 1, :per_page => 25
    else 
      render :nothing => true and return
    end
  end

  private
  
  # A partir de los parámetros identifica el cliente y el item.
  # Si el cliente no existe y está indicado irekia_new_id,
  # se crea el cliente.
  # Si el item no existe (todavía no hay comentarios para la URL indicada)
  # se crea. Así cuando el usuario envía el comentario, el item ya está creado.
  def get_client_and_item
    client_code = params[:client]
    irekia_news_id = params[:news_id]
    content_local_id = params[:content_local_id]
    item_url = params[:url]
    item_title = params[:title].to_s
    
    @client = nil

    if client_code
      @client = ExternalComments::Client.find_by_code(client_code)
    else
     if irekia_news_id.present? || content_local_id.present?
       # Buscar el cliente a través de la url
       client_url, client_code = client_data_from_params()
       @client = ExternalComments::Client.find_by_url(client_url)
       if @client.nil?
         # Si el cliente no está, lo creamos
         @client = ExternalComments::Client.new(:name => client_url, :url => client_url, :code => client_code, :notes => "PENDIENTE")
         if @client.valid?
           @client.save
         else
           logger.error "Error al crear un external_comment_client: #{@client.errors.full_messages.join('. ')}"
         end
       end
     end
    end 

    if @client
      @item = @client.commentable_items.find_by_url(item_url)
      unless @item.present?
        item_title = item_title.encode("utf-8", "ISO-8859-1") unless item_title.is_utf8?
        @item = @client.commentable_items.new(:url => item_url, :title => item_title, :irekia_news_id => irekia_news_id, :content_local_id => content_local_id)
        if @item.valid?
          @item.save
        else
          logger.error "Error al crear un commentable_item: #{@item.errors.full_messages.join('. ')}"
          @item = nil
        end
      end
    end
  end
  
  def client_data_from_params
    url_parts = params[:url].split("/")
    # url_parts = http[s], , domain, client_code-section, locale, content url parts 
    domain = url_parts[2]
    if domain.match("euskadi.net")
      code, section = url_parts[3].split("-")
      client_code = code      
    else
      client_code = ""
    end
    client_url = domain
    client_code = client_url unless client_code.present?
    [client_url, client_code]
  end
  
end
