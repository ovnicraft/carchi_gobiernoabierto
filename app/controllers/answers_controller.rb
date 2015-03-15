class AnswersController < ApplicationController
  before_filter :get_context, :only => [:index]
  
  def index
    finder = @context ? @context.answers : Comment.official.approved
    
    @comments = finder.paginate(:per_page => 15, :page => params[:page]).reorder("created_at DESC")

    @title = t('answers.title')
    
    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => '/shared/list_items', :locals => {:items => @comments}, :layout => false
        else
          render
        end
      end
    end
  end

  private 
  def make_breadcrumbs
    if @context.present?
      @breadcrumbs_info << [t('answers.title'),  send("#{context_type}_answers_path", @context)]
    else
      @breadcrumbs_info = [[t('answers.title'), answers_path]]
    end    
  end

end
