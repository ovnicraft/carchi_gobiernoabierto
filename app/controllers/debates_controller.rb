class DebatesController < ApplicationController
  before_filter :get_context, :only => [:index, :show]
  before_filter :get_criterio, :only => [:show]
  after_filter :track_clickthrough, :only => [:show]

  def index
    prepare_debates

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => '/shared/grid_items', :locals => {:items => @debates}, :layout => false
        else
          render
        end
      end
      format.floki {render :template => "mob_app/debates.json", :layout => false, :content_type => "application/json"}
      format.rss do
        @feed_title = t('debates.feed_title', :name => @context ? @context.name : Settings.site_name)
        render :layout => false
      end
    end
  end

  def show
    begin
      @debate = Debate.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @debate = Debate.find(params[:id])
      if @debate.present? && !(logged_in? && is_admin?)
        raise ActiveRecord::RecordNotFound and return
      end
    end

    @title = @debate.title

    @stage = if params[:stage]
      @debate.stages.find_by_label(params[:stage]).present? ? @debate.stages.find_by_label(params[:stage]) : @debate.current_stage
    else  
      @debate.current_stage
      redirect_to debate_path(:id => @debate.id, :stage => @debate.current_stage.label) and return
    end

    @comments = @debate.comments.approved.paginate :page => params[:page], :per_page => 25
    @arguments = @debate.arguments.published.paginate :page => params[:page], :per_page => 50

    if @stage.label.eql?('conclusions') && @debate.news.present? && @debate.news.published?
      @document = @debate.news
      get_news_videos_and_photos(@document)
      @comments = @document.comments.approved.paginate :page => params[:page], :per_page => 25
    elsif @stage.label.eql?('contribution') && @debate.page.present? && @debate.page.published?  
      @page = @debate.page
    elsif @stage.label.eql?('presentation')
      related_news = @debate.related_news
      @leading_news = @debate.leading_news
      @other_news = related_news - [@leading_news]
      
      # @leading_news = @debate.featured_news.first
      # if @leading_news
      #   @other_news = related_news - [@leading_news]
      # else
      #   @leading_news, @other_news = related_news[0], related_news[1..-1]
      # end
    end
    respond_to do |format|
      format.html
      format.floki
    end
  end

  # Devuelve un archivo zip con todas las fotos o vídeos del documento
  def compress
    @debate = Debate.published.find(params[:id])
    @w = params[:w] && @debate.respond_to?(params[:w]) ? params[:w] : 'photos'

    if @debate.send("zip_#{@w}", I18n.locale)
      send_file(@debate.send("zip_#{@w}_file_#{I18n.locale}"))
    else
      flash[:error] = t('documents.error_zip')
      redirect_to debate_url(:id => @debate.id)
    end
  end

  def department
    @department = Department.find(params[:id])
    @feed_title = t('debates.feed_title', :name => @department.name)
    organization_ids = [@department.id] + @department.organization_ids
    @debates = Debate.published.translated.where("organization_id in (#{organization_ids.join(',')})")
      .reorder('published_at DESC').limit(10)
    render :action => "index.rss", :layout => false
  end

  private

  def prepare_debates
    finder_params = {:per_page => 20, :page => params[:page]}
    if @context
      @debates = @context.debates.published.translated.current
      @finished_debates = @context.debates.published.translated.finished
      @title = t('debates.debates_a', :name => @context.name)
    else
      @title = t('debates.title')
      @debates = Debate.published.translated.current
      @finished_debates = Debate.published.translated.finished      
    end
    @debates = @debates.paginate(finder_params).reorder('published_at DESC')
    @finished_debates = @finished_debates.paginate(finder_params).reorder('published_at DESC')
  end

  def make_breadcrumbs
    if @context.present?
      @breadcrumbs_info << [t('debates.title'),  send("#{context_type}_debates_path", @context)]
    else
      @breadcrumbs_info = [[t('debates.title'), debates_path]]  
      @breadcrumbs_info << [@debate.title, debate_path(:id => @debate)] if @debate.present?
    end    
  end

end
