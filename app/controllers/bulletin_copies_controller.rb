class BulletinCopiesController < ApplicationController
  def show
    @bulletin_copy = BulletinCopy.find(decode_clickthrough(params[:id])[:content_id])
    @web_version = true
    render :template => "/bulletin_mailer/copy", :layout => 'bulletin_mailer'
  end
end
