class VotesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create], if: -> {request.format.to_s.eql?('json')}
  before_filter :login_required
  before_filter :transform_floki_params, :only => :create  
  before_filter :get_votable
  
  def create
    @vote = @votable.votes.new(vote_params.merge(:user_id => current_user.id))

    if @vote.save
      respond_to do |format|
        format.html {
          if request.xhr?
            render :partial => '/votes/votes_form', :locals => {:votable =>@votable}, :layout => false and return
          else  
            flash[:notice] = "Tu voto se ha guardado"
            redirect_to @votable
          end  
        }
        format.floki {
          render :json => {:accepted => true, :requires_moderation => false, :needs_auth => false, :error_message => nil}.to_json
        }
      end
    else
      respond_to do |format|
        format.html {
          if request.xhr?
            render :nothing => true, :status => 500
          else
            flash[:error] = "La valoración no se ha guardado"
            redirect_to @votable
          end
        }
        format.floki {
          render :json => {:accepted => false, :requires_moderation => false, :needs_auth => false, 
                           :error_message => "#{I18n.t('votes.not_saved')}. #{@vote.errors.inject('') {|messages, err| messages += err[1] + ". "}}"}.to_json
        }
      end
    end
  end
  
  private
  def get_votable
    if params[:format].eql?('floki') && params[:proposal_id].to_i.between?(Floki::FACTORS[:proposal], Floki::FACTORS[:vote])
      @votable = Proposal.find(params[:proposal_id].to_i - Floki::FACTORS[:proposal])
      @proposal = @votable
    elsif params[:format].eql?('floki') && params[:debate_id].to_i.between?(Floki::FACTORS[:debate], Floki::FACTORS[:comment])
      @votable = Debate.find(params[:debate_id].to_i - Floki::FACTORS[:debate])
      @debate = @votable
    elsif params[:proposal_id]
      @votable = Proposal.find(params[:proposal_id])
    elsif params[:debate_id]
      @votable = Debate.find(params[:debate_id])      
    end  
  end
  
  def transform_floki_params
    if params[:format].eql?('floki')
      params[:vote] = {:value => tranform_vote_choice}
    end
  end
  
  def tranform_vote_choice
    value = case JSON.parse(params['data'])["vote_choice"].to_i
    when 1
      1
    when 2
      -1
    else
      nil
    end
    value
  end

  def vote_params
    params.require(:vote).permit(:value)
  end
end
