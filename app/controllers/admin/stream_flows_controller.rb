# Controlador para la administración de los flujos de _stream_.
class Admin::StreamFlowsController < Admin::BaseController
  skip_before_filter :admin_required, :only => [:index, :list, :show, :update_status]
  before_filter :stream_access_required
  before_filter :get_stream_flow, :except => [:index, :list, :order, :sort, :new, :create]
  
  # in_place_edit_for :empty_stream_flow, :title_es
  # in_place_edit_for :empty_stream_flow, :title_eu
  # in_place_edit_for :empty_stream_flow, :title_en
  
  # Lista de los flujos de _stream_.
  def index
    @title = t("admin.stream_flows.flujos_stream")
    
    @stream_flows = (StreamFlow.programmed + StreamFlow.announced + StreamFlow.live).uniq
    
    if @stream_flows.empty?
      redirect_to :action => "list" and return
    end
    
    respond_to do |format|
      format.html { render :action => "list"}
      format.xml  { render :xml => @stream_flows }
    end
  end

  def list
    @title = t("admin.stream_flows.flujos_stream")
    sf = StreamFlow.not_empty_streaming
    # sf.each {|s| s.assign_event!}
    @stream_flows = sf+[nil]

    # @empty_stream_flow = get_empty_stream()
    
    respond_to do |format|
      format.html # list.html.erb
      format.xml  { render :xml => @stream_flows }
    end
  end

  # Ver la información sobre un flujo de _stream_ concreto.
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @stream_flow }
    end
  end

  # Formulario para crear un flujo de _stream_ nuevo.
  def new
    @title = "Nuevo flujo de stream"
    @stream_flow = StreamFlow.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @stream_flow }
    end
  end

  # Formulario para modificar un flujo de _stream_.
  def edit
    @title = "Modificar flujo de stream"
    @return_to = request.env["HTTP_REFERER"]
  end

  # Crear un flujo de _stream_ nuevo.
  def create
    @stream_flow = StreamFlow.new(stream_flow_params)

    respond_to do |format|
      if @stream_flow.save
        flash[:notice] = 'El flujo de stream ha sido creado.'
        format.html { redirect_to admin_stream_flows_path() }
        format.xml  { render :xml => @stream_flow, :status => :created, :location => @stream_flow }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @stream_flow.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Modificar los datos de un flujo de _stream_.
  def update
    respond_to do |format|
      if @stream_flow.update_attributes(stream_flow_params)
        flash[:notice] = 'Los datos has sido modificados.'
        format.html { redirect_to params[:return_to].present? ? params[:return_to] : admin_stream_flows_path() }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @stream_flow.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Borrar flujo de _stream_.
  def destroy
    @stream_flow.destroy

    respond_to do |format|
      format.html { redirect_to(admin_stream_flows_url) }
      format.xml  { head :ok }
    end
  end

  # Cambia el estado del streaming dependiendo del valor del submit.
  def update_status
    submit_options = [:show_irekia_on, :show_irekia_off, :announce_irekia_on, :announce_irekia_off]
    
    if params[:submitted_opt].blank?
      @submitted_opt = params.keys.detect {|k| submit_options.include?(k.to_sym)}
    else
      @submitted_opt = params[:submitted_opt]
    end
    
    
    logger.info "submitted_opt: #{@submitted_opt.inspect}"
    @submitted_opt = @submitted_opt.to_sym unless @submitted_opt.nil?

    unless @stream_flow.on_web?
      @stream_flow.event_id = nil
    end
    
    if params[:stream_flow] 
      event_id = params[:stream_flow][:event_id].to_i
      if Event.published.exists?(event_id)
        @stream_flow.event_id = event_id
      else
        @stream_flow.event_id = nil
      end
    end
    
    case @submitted_opt
      when :show_irekia_on, :show_irekia_off
        change_visibility
      when :announce_irekia_on, :announce_irekia_off
        change_announcement      
    end
    
    
    status_file = File.new(@stream_flow.status_file_path, 'w')
    status_file.puts("#{@submitted_opt} event:#{@stream_flow.event_id}")
    status_file.close()    
    
    @stream_flow.save
    @stream_flow.reload

    event_info_file = File.new(@stream_flow.event_info_file_path, 'w')
    if @stream_flow.event
      event_info = ""
      current_locale = @locale
      locales.each do |code, loc|
        I18n.locale = code
        event_info += "<div id='event_#{code}'>"+render_to_string(:partial => '/admin/stream_flows/streamed_event', :object => @stream_flow.event)+"</div>"
      end
      I18n.locale = current_locale
      event_info += render_to_string(:partial => '/admin/stream_flows/streamed_event_json', :locals => {:stream_flow => @stream_flow})
      event_info_file.puts(event_info)
    else
      event_info_file.puts("")
    end
    event_info_file.close()

    respond_to do |format|
      format.html { redirect_to(admin_stream_flows_url) }
      format.js
    end
    
  end

  # Lista de los nombres de los flujos para ordenarlos.
  def order
    @title = "Ordenar los flujos de stream"
    @stream_flows = StreamFlow.not_empty_streaming
  end


  def sort    
    StreamFlow.not_empty_streaming.each do |sf|
      new_position = params["flows"].index(sf.id.to_s)+1
      sf.update_attribute(:position, new_position)
    end 
    render :nothing => true
    
  end
  
  # # In place edit for empty sream flow texts.
  # [:es, :eu, :en:].each do |lang|
  #   define_method("set_empty_stream_flow_title_#{lang}") do
  #     @item = get_empty_stream
  #     attribute = "title_#{lang}"
  #     @item.update_attribute(attribute, params[:value])
  #     render :text => @item.send(attribute).to_s      
  #   end
  # end
  
private

  def set_current_tab
    @current_tab = :stream_flows
  end
  
  # def get_empty_stream
  #   StreamFlow.find_or_initialize_by_code("_empty")    
  # end
  
  def stream_access_required
    unless logged_in? && can_access?("stream_flows")
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def get_stream_flow
    @stream_flow = StreamFlow.find(params[:id])
  end  
  
  
  # Cambiar la visibilidad de un flujo de _stream_.
  #
  # Un flujo de _stream_ puede estar visible en Irekia o en ningún sitio
  def change_visibility
    @css_class_name = "show_in_irekia"

    @show_checked = true    
    case @submitted_opt
      when :show_irekia_on
        @stream_flow.announced_in_irekia = false        
        @stream_flow.show_in_irekia = true
      when :show_irekia_off
        @stream_flow.show_in_irekia = false
        @show_checked = false
        @stream_flow.event_id = nil unless @stream_flow.on_web?       
    end

  end

  # Anunciar próximo streaming.
  #
  # Un flujo de _stream_ puede estar visible en Irekia o en ningún sitio
  def change_announcement
    @css_class_name = "announced_in_irekia"
    
    @show_checked = true    
    case @submitted_opt
      when :announce_irekia_on
        @stream_flow.announced_in_irekia = true
        @stream_flow.show_in_irekia = false
      when :announce_irekia_off
        @stream_flow.announced_in_irekia = false
        @show_checked = false
    end

  end

  def set_event
    event_id = params[:stream_flow][:event_id].to_i
    if Event.published.exists?(event_id)
      @stream_flow.event_id = event_id
    else
      @stream_flow.event_id = nil
    end
  end

  def stream_flow_params
    params.require(:stream_flow).permit(:title_es, :title_eu, :title_en, :code, :mobile_support, :send_alerts,
      :delete_photo, :photo)
  end
  
end
