# Controlador para los eventos públicos
class EventsController < ApplicationController
  before_filter :get_context, :only => [:index, :calendar]
  before_filter :check_politician_has_agenda, :only => [:index]
  before_filter :get_category
  before_filter :get_selected_date, :only => [:index, :summary, :calendar]
  before_filter :get_criterio, :only => [:show]
  after_filter  :track_clickthrough, :only => [:show]

  def index
    prepare_events(@context, request.xhr?)

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => '/shared/list_items', :locals => {:items => @actions, :type => 'events'}, :layout => false
        else
          render
        end
      end
      format.ics { render :layout => false }
      format.rss do
        @feed_title = t('events.feed_title', :name => @context ? @context.name : Settings.site_name)
        render :layout => false
      end
    end
  end
  
  def summary
    get_month_events
    respond_to do |format|
      format.html {render :layout => !request.xhr?}
    end
  end
  
  def list 
    redirect_to url_for(params.merge(:action => 'index'))
  end

  def calendar
    get_month_events
    respond_to do |format|
      format.html {render :layout => !request.xhr?}
    end
  end
  
  # Ver los datos públicos de un evento publicado.
  def show
    @title = t('events.agenda')
    begin
      @event = Event.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      if can_edit?("events")
        @event = Event.find(params[:id])
      else
        if request.format.to_s.eql?("SDP")
          logger.error "ERROR SDP (#{Time.zone.now}): requested #{params[:id]}.#{request.format}"
          request.format = :html
        end
        bad_record
        return
      end
    end
    
    @comments = @event.comments.approved.paginate :page => params[:page], :per_page => 25
    
    if @category
      # Comprobar que la categoria y el documento estan relacionados
      if @event.tags.all_private.collect(&:name_es) & @category.tags.all_private.collect(&:name_es) == []
        logger.info "Categoria y documento no relacionados"
        raise ActiveRecord::RecordNotFound
      end
    end
  
    respond_to do |format|
      format.html { render }
      format.ics { render :layout => false}
      format.xml
      format.floki
    end
  
  end
  
  # RSS de los eventos públicos
  def myfeed
    @title = t('events.agenda')
    cj = get_list_conditions()
    respond_to do |format|
      format.ics {
        @events = Event.published.translated.future(1.month.ago).where(cj[:conditions]).joins(cj[:joins])
        render :layout => false
      }
    end        
  end

  # RSS/ICS para los eventos de cada departamento
  def department
    @department = Department.find(params[:id])
    @feed_title = t('documents.feed_title', :name => @department.name)
    organization_ids = [@department.id] + @department.organization_ids
    @events = Event.published.translated
      .where("organization_id in (#{organization_ids.join(',')})").limit(10).reorder('starts_at DESC')
    respond_to do |format|
      format.ics { render template: 'myfeed', :layout => false }
      format.rss
    end
  end

  def organization
    @organization = Organization.find(params[:id])
    @feed_title = t('documents.feed_title', :name => @organization.name)
    @events = Event.published.translated
      .where("organization_id = #{@organization.id}").limit(10).reorder('starts_at DESC')
    respond_to do |format|
      format.ics { render action: 'myfeed', :layout => false }
      format.rss
    end
  end  
  
  private 
  
  # Los eventos suelen ir debajo de alguna categoría del menú.
  # Aquí se coge la categoría para construir los breadcrumbs.
  def get_category
    @category = Category.find(params[:category_id]) if params[:category_id]
  end
  
  # Construye los breadcrumbs de cada acción de las noticias
  def make_breadcrumbs
    @date ||= Date.today
    if @category
      @category.ancestors.reverse.each {|a| @breadcrumbs_info << [a.name, category_path(a)]}
      @breadcrumbs_info = [[@category.name, category_path(@category)]]
      if @event && !@event.new_record?
        @breadcrumbs_info << [@event.title, category_event_path(@category, @event)]
      end
    elsif @context.present?
      @breadcrumbs_info << [t('events.agenda'), send("#{@context.class.name.to_s.downcase}_events_path", @context)]
    else
      @breadcrumbs_info = [[t('events.agenda'), events_path]]
      if @event && !@event.new_record?
        @breadcrumbs_info << [@event.title,  event_path(@event)]
      end
    end
    @breadcrumbs_info
  end
  
   def get_list_conditions
     @subscription_title = "#{Settings.site_name}::#{t('events.agenda')}"
     
     conditions = {}
     joins = nil
     
     @tag_label = params[:tag_label]
     if @tag_label && Event.show_in_opts.map {|o| "_irekia_#{o}"}.include?(@tag_label)
       if @itag = ActsAsTaggableOn::Tag.find_by_sanitized_name_es(@tag_label)
         conditions['taggings.tag_id'] = @itag.id
         joins = [:taggings]
         @subscription_title = "#{@itag.name}"
       end
     end
     
     @dept_label = params[:dept_label]  || 'all'
     if params[:dept_label]
       tag_name = "_#{params[:dept_label]}".gsub(/[^\w_]/,'')
       if Department.tag_names.include?(tag_name)
         @dept = Department.find_by_tag_name(tag_name)
         conditions["documents.organization_id"] = [@dept.id] + @dept.organization_ids
         @title << ": #{@dept.name}"
         @subscription_title << ": #{@dept.name}"         
       end
     end
       
     {:conditions => conditions, :joins => joins}     
   end


   def prepare_events(context, is_xhr)
     if @context.present?
       events_finder = @context.events
       if params[:year].present? 
         @title = "#{Event.model_name.human(:count => 2).capitalize} #{@context.public_name} #{l(@date, :format => :long)}"
       else
         @title = @context.is_a?(Politician) ? t('politicians.agenda', :name => @context.public_name) : t('areas.agenda', :name => @context.name)      
       end        
     else
       events_finder = Event.published.translated
       if params[:year].present?
         @title = "#{Event.model_name.human(:count => 2).capitalize} #{l(@date, :format => :long)}"
       else
         @title = t('events.comming_events')
       end
     end
     
     if params[:year]
       if request.xhr?
         @actions = events_finder.day_events(@day, @month, @year)
       else
         @actions = events_finder.day_events(@day, @month, @year).paginate(page: params[:page])
         get_month_events
       end
     else
       # Los eventos de hoy más los próximos futuros, hasta 15.
       future_actions = events_finder.where(["ends_at > ?", Time.zone.now.beginning_of_day]).reorder("starts_at")
       @actions = (future_actions | events_finder.reorder("starts_at DESC")).paginate(page: params[:page])
       get_month_events
     end
   end
   
   def check_politician_has_agenda
    if @context.is_a?(Politician) && !@context.politician_has_agenda?
      flash[:notice] = t('politicians.no_tiene_agenda_publica')
      redirect_to request.env["HTTP_REFERER"] ? :back : politician_path(:id => @context, :anchor => 'top') and return
    end
   end
end
