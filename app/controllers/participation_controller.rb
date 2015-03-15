class ParticipationController < ApplicationController
  def show
    if Settings.optional_modules.proposals
      redirect_to proposals_url
    elsif Settings.optional_modules.debates
      redirect_to debates_url
    else
      redirect_to root_url
    end
  end

  def summary
    @proposals = Proposal.approved.published.reorder("published_at DESC").limit(2) if Settings.optional_modules.proposals
    @debates = Debate.published.translated.reorder("published_at DESC").limit(2) if Settings.optional_modules.debates
    respond_to do |format|
      format.html {render :layout => !request.xhr?}
    end
  end
end
