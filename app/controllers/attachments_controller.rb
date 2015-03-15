class AttachmentsController < ApplicationController
  before_filter :get_politician
  
  def new
    @attachment = @politician.attachments.new
  end
  
  def create
    @attachment = @politician.attachments.new(params[:attachment])
    if @attachment.save
      flash[:notice] = t('sadmin.guardado_correctamente', :article => Attachment.model_name.human.gender_article, :what => Attachment.model_name.human)
      redirect_to @politician
    else
      render :action => "new"
    end
  end
  
  def get_politician
    @politician = Politician.find(session[:user_id])
    unless @politician
      access_denied
    end
  end
end
