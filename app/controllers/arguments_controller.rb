class ArgumentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create], if: -> {request.format.to_s.eql?('json')}
  before_filter :login_required
  before_filter :get_argumentable

  before_filter :transform_floki_params, :only => :create
  
  def create
    @argument = @argumentable.arguments.new(argument_params.merge(:user_id => current_user.id))
    if @argument.save
      respond_to do |format|
        format.html do
          if request.xhr?
            if @argument.approved?
              render :partial => "arguments/list_item_in_participation", :locals => {:argument => @argument, :argumentable => @argumentable}, :layout => false
            else
              render :text => "<li><div class='alert alert-info irekia_alert'>#{I18n.t('arguments.moderation_pending')}</div></li>"
            end
          else
            flash[:notice] = "Tu argumento se ha guardado"
            redirect_to @argumentable
          end
        end
        format.floki do
          render :json => {:accepted => true, :requires_moderation => true, :needs_auth => false, :error_message => nil}.to_json
        end
      end
    else
      respond_to do |format|
        format.html do
          if request.xhr?
            render :json => (["Tu argumento no se ha guardado"]+@argument.errors.full_messages).to_json, :status => :error
          else
            flash[:error] = "Tu argumento no se ha guardado"
            redirect_to @argumentable
          end
        end
        format.floki do
          render :json => {:accepted => false, :requires_moderation => false, :needs_auth => false, 
                           :error_message => "#{I18n.t('arguments.not_saved')}. #{@argument.errors.inject('') {|messages, err| messages += err[1] + ". "}}"}.to_json
        end
      end
    end
  end
  
  private
  def get_argumentable
    if params[:format].eql?('floki') && params[:proposal_id].to_i.between?(Floki::FACTORS[:proposal], Floki::FACTORS[:vote])
      @argumentable = Proposal.find(params[:proposal_id].to_i - Floki::FACTORS[:proposal])
      @proposal = @argumentable
    elsif params[:format].eql?('floki') && params[:debate_id].to_i.between?(Floki::FACTORS[:debate], Floki::FACTORS[:comment])
      @argumentable = Proposal.find(params[:debate_id].to_i - Floki::FACTORS[:proposal])
      @proposal = @argumentable
    elsif params[:proposal_id]
      @argumentable = Proposal.find(params[:proposal_id])
    elsif params[:debate_id]
      @argumentable = Debate.find(params[:debate_id])      
    end  

  end
  
  def transform_floki_params
    if params[:format].eql?('floki')
      params[:argument] = {:value => tranform_vote_choice, :reason => params_hash['argument_text']}
    end
  end
  
  def params_hash
    JSON.parse(params['data'])
  end
  
  def tranform_vote_choice
    value = case params_hash["argument_choice"].to_i
    when 1
      1
    when 2
      -1
    else
      nil
    end
    value
  end
  
  def argument_params
    params.require(:argument).permit(:reason, :value)
  end  
  
end
