class OrdersController < ApplicationController
  before_filter :get_criterio, :only => [:show]
  after_filter :track_clickthrough, :only => [:show]  
  
  def show                                                                          
    @order = Order.find_by_no_orden!(params[:no_orden])
    @title = "#{Order.model_name.human} #{@order.no_orden}"
    respond_to do |format|
      format.html
    end
  end                                                                               
  
  def search             
    session[:criterio_id] = nil
    if params[:key].present? && params[:value].present?
      title = "type: orders AND "
      if params[:key].eql?('keyword')
        title << "#{params[:key]}: \"#{params[:value]}\""
        only_title = true
      else
        title << "#{params[:key]}: #{params[:value]}"   
        @sort = 'date'   
        only_title = false     
      end  
      @criterio = Criterio.create(:title => title, :parent_id => nil, :ip => request.remote_ip, :only_title => only_title)
      url = @sort.present? ? search_url(:id => @criterio.id, :sort => 'date') : search_url(:id => @criterio.id)
      redirect_to url and return                                   
    else
      redirect_to request.referer and return
    end   
  end    
                                                                
  private
  def make_breadcrumbs                                                     
    @breadcrumbs_info = []
    @breadcrumbs_info << [t('search.title'), search_url(:id => @criterio.id)] if @criterio.present?
    @breadcrumbs_info << [t('orders.orden_numero', :no => @order.no_orden), order_url(:no_orden => @order.no_orden)] if @order.present?
  end
  
end
