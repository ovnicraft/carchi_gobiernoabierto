class UsersController < ApplicationController
  before_filter :get_user_with_public_page

  def show
    # @actions = get_context_actions(@user)
    @actions = get_user_activity
    respond_to do |format|
      format.html
    end
  end
  
  def get_user_activity
    actions = []
    actions << @user.approved_and_published_proposals
    actions << @user.approved_comments
    actions << @user.approved_arguments
    actions << @user.votes
    actions.flatten.sort_by(&:published_at).reverse[0..19]
  end

  private

  def get_user_with_public_page
    begin
      @user = User.approved.find(params[:id])
      raise ActiveRecord::RecordNotFound if @user.is_admin?
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = t('people.not_found')
      redirect_to root_path and return
    end
  end

  def make_breadcrumbs
    @breadcrumbs_info = [[@user.public_name, user_path(@user)]] if @user.present?
  end    
  
end
