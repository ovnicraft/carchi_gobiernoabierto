class Admin::BulletinCopiesController < Admin::BaseController
  def show
    @bulletin_copy = BulletinCopy.find(params[:id])
    @web_version = true
    @trackable = false
    render :template => "/bulletin_mailer/copy", :layout => 'bulletin_mailer'
  end

  def create
    bulletin = Bulletin.create
    copy = bulletin.bulletin_copies.build(bulletin_copy_params)

    if copy.save && copy.sent?
      logger.info "AAAAAAAAAAAA sending news #{copy.bulletin.featured_news_ids.inspect} and #{copy.news_ids.inspect}"
      flash[:notice] = "El ejemplar se ha enviado correctamente"
      logger.info "El boletín para #{copy.user.email} se ha creado"
    else
      flash[:error] = "El ejemplar NO se ha enviado correctamente. Inténtelo más tarde"
      logger.info "El boletín #{copy.id} para #{copy.user.email} NO se ha enviado: #{copy.errors.full_messages.join('. ')}"
    end
    redirect_to admin_user_path(copy.user, :subtab => "bulletins")
  end

  private
  def bulletin_copy_params
    params.require(:bulletin_copy).permit(:user_id)
  end
end
