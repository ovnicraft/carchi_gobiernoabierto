class MobApp::IuiController < ApplicationController
  before_filter :login_required
  skip_before_action :verify_authenticity_token, only: [:step], if: -> {request.format.to_s.eql?('floki')}
  
  def new
    @s = 1
    render :action => "#{params[:what]}.json", :content_type => "application/json", :layout => false
  end
  
  def step
    @s = params[:s].to_i
    render :action => "#{params[:what]}.json", :content_type => "application/json", :layout => false
  end
end
