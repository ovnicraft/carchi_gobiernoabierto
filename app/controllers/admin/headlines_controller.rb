class Admin::HeadlinesController < Admin::BaseController
  skip_before_filter :verify_authenticity_token, :only => [:update, :auto_complete_for_headline_tag_list_without_areas]
  # skip_before_filter :admin_required, :approved_user_required, :only => [:auto_complete_for_headline_tag_list_without_areas, :delete_from_entzumena]
  skip_before_filter :admin_required, :approved_user_required
  before_filter :access_to_headlines_required, :except => [:delete_from_entzumena]

  auto_complete_for :headline, :tag_list_without_areas

  def index
    @title = t('headlines.title')
    @sort_order = params[:sort] ||  "published_at"

    case @sort_order
    when "published_at"
      order = "published_at DESC, score DESC, title"
    when "title"
      order = "lower(tildes(title)), published_at DESC, score DESC"
    when "media"
      order = "lower(tildes(media_name)), published_at DESC, score DESC"
    end

    conditions = []
    cond_values = {}

    if params[:q].present?
      conditions << "lower(tildes(title)) like :q"
      cond_values[:q] = "%" + params[:q].tildes.downcase + "%"
    end

    @headlines = Headline.where([conditions.join(' AND '), cond_values])
        .paginate(:page => params[:page], :per_page => 20).reorder(order)
  end

  def update
    @headline = Headline.find(params[:id])
    if params[:build_params].present? && params[:build_params].eql?('true')
      headline_params={}
      headline_params.merge!(:area_tags => [params[:area_tags]]) if params[:area_tags].present?
      headline_params.merge!(:locale => params[:hl_locale]) if params[:hl_locale].present?
      headline_params.merge!(:tag_list => params[:tag_list]) if params[:tag_list].present?
    else
      headline_params = params.require(:headline).permit(:draft)
    end
    unless @headline.update_attributes(headline_params)
      render status: 422
    end
  end

  def update_area
    @headline = Headline.find(params[:id].to_i)
    unless @headline.update_attributes({:area_tags => [params[:area_tags]]})
      render status: 422
    end
  end

  # API to delete item from entzumena.irekia.euskadi.net
  def delete_from_entzumena
    headline = Headline.where({:source_item_type => params[:source_item_type], :source_item_id => params[:source_item_id]}).first
    if headline.destroy
      render :json => true, :status => 200
    else
      render :json => false, :status => :error
    end
  end

  def destroy
    @headline = Headline.find(params[:id])
    if @headline.destroy
      respond_to do |format|
        format.html do
          flash[:notice] = 'La referencia se ha eliminado correctamente'
          redirect_to admin_headlines_path
        end
        format.js
      end
    end
  end

  # Auto complete para los tags
  def auto_complete_for_headline_tag_list_without_areas
    auto_complete_for_tag_list_first_beginning_then_the_rest(params[:headline][:tag_list_without_areas])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.name)}.join.html_safe) %>"
    else
      render :nothing => true
    end
  end

  private

  def set_current_tab
    @current_tab = :headlines
  end

  def access_to_headlines_required
    unless (logged_in? && can?("approve", "headlines"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

end
