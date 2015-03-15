class StreamingsController < ApplicationController
  before_filter :admin_required, :only => [:update_watchers_info]
  before_filter :http_authentication4streaming, :only => [:live]
  
  def index
    @flows = StreamFlow.where("announced_in_irekia = 't' OR show_in_irekia = 't'").order('updated_at DESC')
  end

  def show
    @streaming = StreamFlow.find(params[:id])
    
    if request.xhr?
      if @streaming.show_in_irekia?
        render :partial => "streamings/live_streaming", :locals => {:event => @streaming.event, :streaming => @streaming}
      else
        render :partial => "streamings/finished_streaming"
      end
    else
      if @streaming.event 
        if  @streaming.event.published?
          redirect_to event_url(@streaming.event)
        else
          raise ActiveRecord::RecordNotFound unless (@streaming.on_air? || @streaming.announced?)
        end
      else
        if !@streaming.on_air? && !@streaming.announced?
          raise ActiveRecord::RecordNotFound
        end
      end
    end
  end

  def live
    @streaming = StreamFlow.find(params[:id])
    unless @streaming.code.match(/IREKIABETA/i)
      raise ActiveRecord::RecordNotFound
    end
    render :action => 'show'
  end

  def update_watchers_info
    @stream_flow = StreamFlow.find(params[:id])
    render :update do |page| 
      page.replace_html "sf_watchers_info", admin_show_streaming_watchers(@stream_flow)
    end    
  end

  def make_breadcrumbs
    @breadcrumbs_info = []
    
    if @streaming.present?
      @breadcrumbs_info << [@streaming.title,  streaming_path(@streaming)]
    end
  end
  
  private
  
  def http_authentication4streaming
    authenticate_or_request_with_http_basic do |username, password|
      username == "irekia-live" && password == "25-01-2012"
    end
  end
end
