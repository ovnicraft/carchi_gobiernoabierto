class FollowingsController <ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :destroy], if: -> {request.format.to_s.eql?('json')}
  before_filter :login_required, :only => [:create, :destroy]

  def index
    if params[:user_id]
      @user = User.find(params[:user_id])
      @following_politicians = @user.following_politicians
      @following_areas = @user.following_areas
      respond_to do |format|
        format.html
      end
    else
      redirect_to logged_in? ? account_path : root_url
    end
  end

  def create
    @following = Following.new(following_params.merge(:user_id => current_user.id))
    @item = @following.followed
    if @following.save
      respond_to do |format|
        format.html {
          render :template => 'followings/update_all', :locals => {:item => @following.followed, :action => 'destroy'}, :layout => !request.xhr?
        }
        format.json {
          render :action => 'follow.json', :layout => false
        }
        format.floki {
          render :action => 'follow.json', :layout => false
        }
      end
    else
      respond_to do |format|
        format.html {
          @following=Following.where(params[:following].to_h).first
          # render :json => t('followings.ya_existe').to_json, :status => 500
          if @following
            render :partial => 'followings/destroy', :layout => false, :status => 500
          else
            render :nothing => true, :layout => false, :status => 500
          end
        }
        format.json {
          @item = @following.followed
          render :action => 'follow.json', :layout => false
        }
        format.floki {
          @item = @following.followed
          render :action => 'follow.json', :layout => false
        }
      end
    end
  end

  def destroy
    if params[:id].to_i == 0
      destroyed_following = current_user.followings.where({:followed_id => params[:item_id].to_i , :followed_type => params[:item_type]}).first
    else
      destroyed_following = Following.find(params[:id])
    end
    @item = destroyed_following.followed
    if destroyed_following.present? && destroyed_following.destroy
      respond_to do |format|
        format.html {
          @following = Following.new
          # redirect_back_or_default(root_path)
          render :template => 'followings/update_all', :locals => {:item => destroyed_following.followed, :action => 'create'}, :layout => !request.xhr?
        }
        format.json {
          render :action => 'follow.json', :layout => false
        }
        format.floki {
          render :action => 'follow.json', :layout => false
        }
      end
    else
      respond_to do |format|
        format.html {
          render :nothing => true, :status => :error
        }
        format.json {
          render :action => 'follow.json', :layout => false
        }
        format.floki {
          render :action => 'follow.json', :layout => false
        }
      end
    end
  end

  def state
    @item = params[:type].constantize.find(params[:id])
    render :action => "follow_state.json", :layout => false
  end

  private

  def make_breadcrumbs
    @breadcrumbs_info = []
    if params[:action].eql?('index') && @user.present?
      @breadcrumbs_info << [@user.public_name, user_path(@user)]
      @breadcrumbs_info << [t('users.followings'), url_for(:controller => 'followings', :action => 'index', :user_id => @user.id)]
    end
  end

  def following_params
    params.require(:following).permit(:followed_id, :followed_type)
  end

end
