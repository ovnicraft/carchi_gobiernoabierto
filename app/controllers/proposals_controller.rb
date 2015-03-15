# Controlador para las propuestas ciudadanas
class ProposalsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create], if: -> {request.format.to_s.eql?('json')}
  before_filter :login_required, :only => [:new, :create]
  before_filter :get_context, :only => [:index]
  before_filter :get_criterio, :only => [:show]
  after_filter :track_clickthrough, :only => [:show]

  before_filter :transform_floki_params, :only => :create


  # Listado de propuestas
  def index
    get_proposals

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => '/shared/list_items', :locals => {:items => @proposals, :type => 'proposals'}, :layout => false
        else
          render
        end
      end
      format.floki {render :template => "mob_app/proposals.json", :layout => false, :content_type => "application/json"}
      format.rss do
        @feed_title = t('proposals.feed_title', :name => @context ? @context.name : Settings.site_name)
        render :layout => false
      end
    end
  end

  def summary
    @proposals = Proposal.approved.published.reorder("published_at DESC").limit(2)
    @debates = Debate.published.translated.reorder("published_at DESC").limit(2)
    respond_to do |format|
      format.html {render :layout => !request.xhr?}
    end
  end

  # Vista de una propuesta
  def show
    begin
      @proposal = Proposal.approved.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @proposal = Proposal.find_by_id(params[:id].to_i)
      if @proposal.present? && !(logged_in? && (is_admin? || @proposal.user_id == current_user.id))
        raise ActiveRecord::RecordNotFound and return
      elsif @proposal.nil?
        @debate = Debate.published.find(params[:id])
        redirect_to debate_path(@debate) and return
      end
    end

    @parent = @proposal

    @comments = @proposal.comments.approved.paginate :page => params[:page], :per_page => 25
    @arguments = @proposal.arguments.published.paginate :page => params[:page], :per_page => 50

    if logged_in? && params[:n_id].present?
      notification = current_user.notifications.find(params[:n_id])
      notification.read_at = Time.zone.now if notification.read_at.nil?
      notification.save
    end

    respond_to do |format|
      format.html { render }
      format.floki { render }
    end
  end

  # Formulario de nueva propuesta ciudadana
  def new
    @proposal = Proposal.new
    @proposal.area_tags = [Area.find(params[:area_id]).area_tag.name_es] if params[:area_id]
    respond_to do |format|
      format.html
      format.floki { render :action => 'new.floki', :content_type => 'application/json', :layout => false}
    end
  end

  # Creación de nueva propuesta ciudadana
  def create
    @proposal = current_user.proposals.new(proposal_params)
    # @proposal.organization_id = Organization.find_by_tag_name("_gobierno_vasco") if @proposal.organization_id.blank?
    if @proposal.save
      Notifier.new_proposal(@proposal).deliver

      respond_to do |format|
        format.html do
          if request.xhr?
            render :action => "create", :layout => false
          else

            if @proposal.approved?
              flash[:notice] = t('proposals.gracias')
            else
              flash[:notice] = t('proposals.gracias_revisaremos')
            end
            redirect_to proposals_path(:s => "f")
          end
        end
        format.json do
          render :json => {:sequence_finished => true,
                           :success_message => @proposal.approved? ? t('proposals.gracias') : t('proposals.gracias_revisaremos'),
                           :refresh_controller => true}.to_json

        end
      end
    else
      respond_to do |format|
        format.html {render :action => "new"}
        format.json {render :json => {:error_message => @proposal.errors.inject('') {|messages, err| messages += err[1] + ". "},
          :needs_auth => false}.to_json}
      end
    end
  end

  def image
    uploader = ImageUploader.cache_from_io!(request.body, params.delete(:qqfile))
    @image = {
      :success => true,
      :image_cache_name => uploader.cache_name
    }
    render :text => @image.to_json and return
  end

  def department
    @department = Department.find(params[:id])
    @feed_title = t('proposals.feed_title', :name => @department.name)
    organization_ids = [@department.id] + @department.organization_ids
    @proposals = Proposal.approved.published.where("organization_id in (#{organization_ids.join(',')})")
      .reorder('published_at DESC').limit(10)
    respond_to do |format|
      format.rss {render :action => "index.rss", :layout => false}
    end
  end

  private
  def transform_floki_params
    if params[:format].eql?('json')
      params[:proposal] = JSON.parse(params['data'])
    end
  end

  def make_breadcrumbs
    if @context.present?
      # context_type = @context.class.name.to_s.downcase.eql?('person') ? 'user' : @context.class.name.to_s.downcase
      @breadcrumbs_info << [t('proposals.title'),  send("#{context_type}_proposals_path", @context)]
    else
      @breadcrumbs_info = [[t('proposals.title'), proposals_path]]
      if @proposal.present? && @proposal.new_record?
        @breadcrumbs_info << [t('proposals.nueva_propuesta'), new_proposal_path]
      elsif @proposal.present? && !@proposal.new_record?
        @breadcrumbs_info << [@proposal.title, proposal_path(:id => @proposal)]
      end

    end
  end

  def get_proposals
    order = params[:more_polemic] ? "comments_count DESC" : "proposals.published_at DESC"
    finder_params = {:per_page => 20, :page => params[:page]}

    if @context
      @proposals = @context.approved_and_published_proposals # Propuestas que ha hecho
      @title = @context.is_a?(Area) ? t('proposals.propuestas_a', :name => @area.name) : t("proposals.politician_proposals.#{am_I?(@politician) ? 'yours' : 'others'}")
    else
      @title = t('proposals.title')
      @proposals = Proposal.approved.published
    end
    @proposals = @proposals.paginate(finder_params).reorder(order)
  end

  def proposal_params
    params.require(:proposal).permit(:name, :title_es, :title_eu, :title_en,
      :body_es, :body_eu, :body_en, :image, :title, :body, :tag_list, :area_tags=> [])
  end

end
