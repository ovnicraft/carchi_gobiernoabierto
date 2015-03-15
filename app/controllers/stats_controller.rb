class StatsController < ApplicationController

  def index
    if params[:item_type] && params[:item_id]
      @item = params[:item_type].classify.constantize.find(params[:item_id])
    end
    @stats_for = request.referer.to_s.gsub(/https?:\/\/www\.irekia\.euskadi\.net/, '')
    # render :action => 'index.js.erb', :layout => false
    render :layout => false
  end

end
