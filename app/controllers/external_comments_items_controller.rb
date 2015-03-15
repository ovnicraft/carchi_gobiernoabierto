class ExternalCommentsItemsController < ApplicationController
  
  def show
    @item = ExternalComments::Item.find(params[:id])
    redirect_to embed_comments_url(:url => @item.url)
  end

end
