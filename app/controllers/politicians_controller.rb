class PoliticiansController < ApplicationController
  before_filter :get_selected_date, :only => :show
  before_filter :get_politician, :except => [:index]
  
  def index
    if params[:area_id]
      @area = Area.find(params[:area_id])
      @politicians = @area.users.approved
      get_followings
    else
      # First, lehendakari, then the rest
      @politicians = Politician.approved.order("(CASE WHEN public_role_es='Lehendakari' THEN 0 ELSE 1 END), last_names")
    end   
    respond_to do |format|
      format.html
    end
  end
  
  def show
    # get_actions
    @context = @politician
    prepare_news(@context, request.xhr?)
    render :template => '/news/index'
  end
  
  def what
    @what = params[:w]
    if @what.present?
      @what_content = @politician.send(@what)
    end
    respond_to do |format|
      format.floki { render :action => "what.floki", :layout => "application.floki" }
    end
  end
  
  private

  def get_politician
    @politician = Politician.approved_or_ex.find(params[:id])
  end

  def get_actions
    @actions = get_context_actions(@politician)
    @politician.areas.each do |area|
      @actions += get_context_actions(area)
    end
    @actions = @actions.uniq
  end
  
  def make_breadcrumbs
    if @area.present?
      @breadcrumbs_info = [[t('organizations.title'), areas_path]]
      @breadcrumbs_info << [@area.name,  area_path(@area)]
      @breadcrumbs_info << [t("politicians.title"), area_politicians_path(@area)]
    else  
      @breadcrumbs_info = [[t('politicians.title'), politicians_path]]
      @breadcrumbs_info << [@politician.public_name,  politician_path(@politician)] if @politician  
    end  
    
  end    
end
