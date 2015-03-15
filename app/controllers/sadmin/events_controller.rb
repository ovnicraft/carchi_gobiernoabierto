#
# Controlador para el acceso a las agendas desde la parte de administración de la web.
#
# Sólo los usuarios que tienen permiso para ver las agendas pueden acceder a este controlador.
#
class Sadmin::EventsController < Sadmin::BaseController
  before_filter :access_to_events_required, :except => [:myfeed]

  before_filter :get_title, :only => [:index, :calendar, :list, :week]

  before_filter :get_calendar_events, :only => [:index, :calendar]

  before_filter :get_event, :only => [:show, :edit, :update, :unrelate, :set_event_related_news_title]
  before_filter :edit_permission_required, :except => [:index, :calendar, :list, :week, :myfeed, :show]
  before_filter :get_selected_date, :only => [:list, :new, :week, :week2]

  cache_sweeper :event_sweeper, :only => [ :update, :delete]

  auto_complete_for :event, :place
  auto_complete_for :event, :related_news_title
  # in_place_edit_for :event, :related_news_title

  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_event_place, :auto_complete_for_event_related_news_title, :auto_complete_for_event_politicians_tag_list]

  uses_tiny_mce :only => [:new, :create, :edit, :update], :options => Admin::BaseController::TINYMCE_OPTIONS

  # Calendario de los eventos del mes actual.
  def index
    respond_to do |format|
      format.html {
        render
      }
      format.ics {
        @events = Event.where(["starts_at >= ?", 3.months.ago])
        render :layout => false
      }
    end
  end

  # RSS de todos los eventos
  def myfeed
    if params[:u] && params[:p]
      user = User.authenticate_from_url(params[:u], params[:p])
    end

    if user && user.can_access?("events")
      respond_to do |format|
        format.ics {
          # Eventos públicos o privados que ven todos los usuarios con acceso a la agenda.
          @events = Event.where(["starts_at >= ?", 3.months.ago])
          render :layout => false
        }
      end
    else
      flash[:notice] = t('no_tienes_permiso')
      redirect_to "index"
    end
  end

  # Lista de los eventos de un día.
  def list
    for_date =  Date.new(@selected_date[:year], @selected_date[:month], @selected_date[:day])

    conditions = ["(starts_at <= :end_hour) and (ends_at >= :beginning)", {:beginning => for_date.beginning_of_day, :end_hour => for_date.end_of_day}]

    @documents = Event.where(conditions).reorder("starts_at").sort {|a,b| a.sort_position <=> b.sort_position}


    # @title = t("documents.#{@t.titleize}")
    @subtitle = I18n.localize(for_date, :format => :long)
    @prev_day = for_date - 1.day
    @next_day = for_date + 1.day

    # If there are no events, redirect to the create event form.
    redirect_to new_sadmin_event_path(@selected_date) if @documents.empty?  && can_create?("events")
  end

  # Lista de los eventos en una semana.
  def week
    for_date =  Date.new(@selected_date[:year], @selected_date[:month], @selected_date[:day])

    @first_day_of_week = for_date.beginning_of_week

    conditions = ["(starts_at <= :end_hour) and (ends_at >= :beginning)", {:beginning => for_date.beginning_of_week.to_time, :end_hour => for_date.end_of_week.to_time.end_of_day}]

    @events = Event.where(conditions).reorder("starts_at")

    #@title = t("documents.#{@t.titleize}")
    @subtitle = "#{I18n.localize(for_date.beginning_of_week, :format => :long)} - #{I18n.localize(for_date.end_of_week, :format => :long)}"
  end

  # Vista alternativa para los eventos de una semana.
  def week2
    week
  end

  # Formulario para crear un nuevo evento.
  def new
    @title = t('sadmin.create_what', :what => Event.model_name.human)

    begin
      default_date = Date.parse("#{@year}-#{@month}-#{@day}")
    rescue ArgumentError
      default_date = Time.zone.now
    end

    event_params =  { :starts_at => default_date, :ends_at => default_date,
                      :organization_id => current_user.department_id,
                      :has_journalists => false, :has_photographers => false}

    @event =  Event.new(event_params) if can_create?('events')
  end

  # Crear un evento nuevo.
  #
  # Si los datos son correctos el evento se crea y se muestra la página del evento nuevo.
  # Si algún dato no es válido, se muestra de nuevo el formulario con explicación
  # sobre los datos que no son válidos.
  def create
    @title = t('sadmin.create_what', :what => Event.model_name.human)

    if can_create?('events')
      @event = Event.new(event_params)
      if @event.save
        flash[:notice] = t('sadmin.events.guardado_correctamente', :what => Event.model_name.human)
        redirect_to sadmin_event_path(@event.id, :fresh => 1)
      else
        render :action => 'new'
      end
    else
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end

  end

  # Página de un evento. Se muestran todos los datos del evento.
  def show
    @just_created = params[:fresh].to_i.eql?(1)
    if @just_created
      @selected_date = {}
      [:year, :month, :day].each do |key|
        @selected_date[key] = @event.starts_at.send(key.to_s)
      end
    end
    respond_to do |format|
      format.html {
        render
      }
      format.ics {
        render :layout => false
      }
    end
  end

  # Formulario para modificar los datos de un evento.
  def edit
    @title = t('sadmin.modificar_what', :what => Event.model_name.human)
  end

  # Modificar los datos de un evento.
  #
  # Si los datos son válidos, estos se guardan en la base de datos y se muestra el evento.
  # Si los datos no son válidos se muestra el formulario con los mensajes de error correspondientes.
  def update
    @title = t('sadmin.modificar_what', :what => Event.model_name.human)

    if @event.update_attributes(event_params)
      flash[:notice] = t('sadmin.events.guardado_correctamente', :what => Event.model_name.human)
      redirect_to sadmin_event_path(:id => @event.id)
    else
      render :action => params[:return_to] || 'edit'
    end
  end

  # Calendario de los eventos en un mes.
  def calendar
    @t = "events"

    respond_to do |format|
      format.html do
        render :action => 'index'
      end
      format.js
      format.xml  { head :ok }
    end
  end

  # Marcar un evento como 'borrado'.
  def mark_for_deletion
    @event = Event.find(params[:id])
  end

  # Borrar un evento.
  def delete
    @event = Event.find(params[:id])

    unless params[:cancel]
      if @event.update_attributes(:deleted => true)
        flash[:notice] = t('sadmin.events.marcado_eliminado')
      else
        flash[:error] = t('sadmin.events.no_marcado_eliminado')
      end
    end
    redirect_to sadmin_event_path(@event)
  end

  def unrelate
    if rel = @event.related_items.find_by_eventable_id(params[:related_item_id])
      rel.destroy
    end
    redirect_to sadmin_event_path(:id => @event.id)
  end

  # Inplace editor call
  def set_event_related_news_title
    unless ['POST', 'PUT'].include?(request.method) then
      return render(:text => 'Method not allowed', :status => 405)
    end
    @event.update_attribute(:related_news_title, params[:value])
  end

  #
  # Autocomplete para el nombre del sitio
  #
  def auto_complete_for_event_place
    places = EventLocation.where(["tildes(place) ilike ?", "%"+params[:event][:place].tildes+"%"])
    render :partial => 'event_locations', :object => places
  end

  #
  # Autocomplete para el título de la noticia relacionada
  #
  def auto_complete_for_event_related_news_title
    @items = News.where(["tildes(title_es) ILIKE ?", params[:value]+'%'])
    render :inline => "<%= content_tag(:ul, @items.map {|item| content_tag(:li, item.title)}.join.html_safe) %>"
  end

  #
  # Autocomplete para la lista de políticos
  #
  def auto_complete_for_event_politicians_tag_list
    auto_complete_for_document_politicians_tag_list(params[:event][:politicians_tag_list])
  end


  private

  def get_selected_date
    @selected_date = {}
    @today = Time.zone.now
    [:year, :month, :day].each do |key|
      @selected_date[key] = (params[key].to_i > 0) ? params[key].to_i : @today.send(key.to_s)
    end

    @today = Time.zone.now
    @year = @selected_date[:year]
    @month = @selected_date[:month]
    @day = @selected_date[:day]
  end

  def set_current_tab
    @t = "events"
    @pretty_type = t("documents.#{@t.titleize.singularize}").singularize

    @current_tab = @t.to_sym
    @current_tab
  end

  def get_calendar_events
     get_selected_date
     @events = Event.month_events_by_day4cal(@month, @year)

     # borar del hash events los eventos que no necesitamos para el calendario del mes

     first_day_of_month = Date.new(@year, @month, 1).to_datetime
     first_week = first_day_of_month.at_beginning_of_week
     last_week = first_day_of_month.at_end_of_month.at_end_of_week
     cal_months = [first_day_of_month.month, first_week.month, last_week.month].uniq.sort
     @events.to_a.delete_if {|key, value| !cal_months.include?(key)} if @events
     @events[first_week.month].delete_if {|key, value| !(first_week.day..first_week.at_end_of_month.day).include?(key)} if @events[first_week.month]
     @events[last_week.month].delete_if {|key, value| !(last_week.at_beginning_of_month.day..last_week.day).include?(key)} if @events[last_week.month]

     sort_day_events
  end

  def sort_day_events
    # sort day events by hour
    @events.keys.each do |m|
      @events[m].each do |day, ev_list|
         ev_list.sort! {|a,b| a.sort_position <=> b.sort_position}
      end
    end
  end

  def get_event
    @event = Event.find(params[:id])
  end

  def get_title
    @title = t('sadmin.events.agenda_compartida')
  end

  def access_to_events_required
    permission_ok = false
    if (logged_in?)
      if can_access?("events")
        permission_ok = true
      end
    end

    unless permission_ok
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def edit_permission_required
    permission_ok = false
    if (logged_in?)
      if @event
        permission_ok = can_edit_event?(@event)
      else
        if can_edit?("events")
          permission_ok = true
        end
      end
    end

    unless permission_ok
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def restrict_events?
    current_user.is_a?(DepartmentMember)
  end

  def event_params
    # preserve this order: only_photographers must apply before all_journalists
    params.require(:event).permit(:starts_at, :ends_at, :politicians_tag_list,
                                  :speaker, :organization_id, :title_es, :title_eu, :title_en, :place,
                                  :city, :location_for_gmaps, :body_es, :body_eu, :body_en, :is_private,
                                  :alertable, :only_photographers, :all_journalists, :alert_this_change,
                                  :area_tags => [])
  end

end
