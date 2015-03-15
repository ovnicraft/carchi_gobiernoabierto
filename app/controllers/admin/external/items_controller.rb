class Admin::External::ItemsController < Sadmin::BaseController
  before_filter :get_client
  
  def index
    @items = @client.commentable_items.order("created_at DESC")
  end

  private
  
  def get_client
    @client = ExternalComments::Client.find(params[:external_client_id])
  end

  def set_current_tab
    @current_tab = :comments
  end
  
end
