class AreasController < ApplicationController
  before_filter :get_selected_date, :only => :show

  def index
    @areas = Area.order('position')
    respond_to do |format|
      format.html {
        if !request.xhr?
          render :action => 'index'
        else
          render :action => 'list', :layout => !request.xhr?
        end
      }
    end
  end

  def show
    if params[:id].to_i.eql?(10)
      params[:id] = 13
    end
    @area = Area.find(params[:id])
    @context = @area
    prepare_news(@context, request.xhr?)
    render :template => '/news/index'
  end
  
  def what
    @area = Area.find(params[:id]) 
    respond_to do |format|
      format.html { render }
      format.xml
      format.floki { render :action => "what.floki", :layout => "application.floki" }
    end    
  end
  
  private
  
  def make_breadcrumbs
    @breadcrumbs_info = [[t('organizations.title'), areas_path]]
    @breadcrumbs_info << [@area.name,  area_path(@area)] if @area
  end

  # NOT USED
  def get_area_activity
    @content = get_context_actions(@area)

    # @content = []
    # @content << @area.news 
    #   .select("documents.id, title_es, title_eu, title_en, body_#{I18n.locale}, published_at, has_comments, comments_closed, comments_count")
    #   .order('published_at DESC').limit(20)
    #  
    # events = @area.events.current
    #   .select("documents.id, title_#{I18n.locale}, body_#{I18n.locale}, starts_at, ends_at, place")
    #   .order('starts_at DESC').limit(3)
    #   
    # @content << @area.proposals
    #   .select("proposals.id, title_es, title_eu, title_en, body_#{I18n.locale}, published_at, status, user_id, has_comments, comments_closed")
    #   .order('published_at DESC').limit(20)
    #   
    # 
    # @content = events + @content.flatten.sort {|a,b| string_to_time(b.published_at) <=> string_to_time(a.published_at)}[0..19]
    # #@content = @content.flatten.sort {|a,b| string_to_time(b.published_at) <=> string_to_time(a.published_at)}[0..19]
  end
    
end
