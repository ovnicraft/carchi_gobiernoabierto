class RecommendationRatingsController < ApplicationController

  def create
    if request.xhr?
      @rating = RecommendationRating.new :source_type => params[:s_type], :source_id => params[:s_id], 
      :target_type => params[:t_type], :target_id => params[:t_id], 
      :user_id => current_user.id, :rating => params[:rating]
      @rating.save              
      render :nothing => true
    else
      if params[:t_type].eql?('Document')
        target_id=params[:t_id]
      elsif params[:t_type].eql?('Order')
        target=Order.find_by_no_orden(params[:t_id])
        target_id=target.id if target.present?
      end
      @rating = RecommendationRating.new(:source_type => params[:s_type], :source_id => params[:s_id], 
      :target_type => params[:t_type], :target_id => target_id, 
      :user_id => current_user.id, :rating => params[:rating], :create_reciprocal => true)
      unless @rating.save
        flash[:error] = t('shared.sidebar.error_añadir_relacionado')
      end
      if @rating.source.is_a?(Document)
        redirect_to @rating.source	
      else
        redirect_to order_url(:no_orden => @rating.source.no_orden)		
      end	
    end			
  end

end
