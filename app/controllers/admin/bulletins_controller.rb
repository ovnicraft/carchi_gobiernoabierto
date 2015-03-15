class Admin::BulletinsController < Admin::BaseController
  def index
    @news = News.published.translated.listable
      .where(Bulletin.sent.count > 0 ? ["published_at > ?", Bulletin.sent.last.sent_at] : nil)
      .reorder("published_at DESC").limit("100")
  end

  def mark_candidates
    begin
    Bulletin.transaction do
      News.update_all("featured_bulletin='f'")
      News.where("id IN (#{params[:candidates].join(',')})").update_all("featured_bulletin='t'") if params[:candidates].present?
    end
    rescue
      flash[:error] = 'Las noticias seleccionadas no se han guardado correctamente. Por favor, vuelve a intentarlo.'
    else
      flash[:notice] = 'Las noticias seleccionadas se han guardado correctamente.'
    end
    redirect_to admin_bulletins_path
  end

  def archive
    @bulletins = Bulletin.where("sent_at IS NOT NUll").paginate(:page => params[:page], :per_page => 20).reorder("sent_at DESC")
  end

  def subscribers
    conditions = params[:q].present? ? ["lower(tildes(name || coalesce(last_names, '') || coalesce(telephone, '') || coalesce(email, '')))  like ? ", "%#{params[:q].tildes.downcase}%"] : nil
    @subscribers = Bulletin.subscribers.where(conditions).paginate(page: params[:page]).reorder("tildes(lower(name))")
  end

  def show
    @bulletin = Bulletin.find params[:id]
    @copies = @bulletin.bulletin_copies.where("sent_at IS NOT NUll").paginate(:page => params[:page], :per_page => 20)
      .order("sent_at DESC")
  end

  def new
    @bulletin = get_unsent_bulletin # Bulletin.new
    get_candidates
  end

  def create
    @bulletin = get_unsent_bulletin # Bulletin.new(params[:bulletin])
    # @bulletin.attributes = (bulletin_params || {}).reverse_merge({:featured_news_ids => [], :featured_debate_ids => []})
    if @bulletin.update_attributes(bulletin_params)
      prepare_bulletin_preview
    else
      get_candidates
      render :action => 'new'
    end
  end

  def program
    @bulletin = Bulletin.unsent.first
    @bulletin.send_at = Time.zone.now
    if @bulletin.save
      News.update_all("featured_bulletin='f'")
      Debate.update_all("featured_bulletin='f'")
      render :text => "<div class='flash_notice'>El envío del boletín se ha programado correctamente y comenzará en unos minutos.</div>", :layout => "admin"
    else
      flash[:error] = "El boletín no se ha programado para enviar. Intentelo más tarde o contacte con soporte."
      redirect_to new_admin_bulletins_path
    end
  end

  def announce
    user = User.find(1927) #Tania
    notification = BulletinMailer.announce(user)
    begin
      notification.deliver
    rescue => err_type
      alert_logger.info("\tThere were some errors sending event alert: " + err_type)
    end
    render :nothing => true
  end

  private

  def set_current_tab
    @current_tab = :bulletins
  end

  def get_unsent_bulletin
    bulletin = Bulletin.unsent.first
    bulletin ||= Bulletin.new
    return bulletin
  end

  def prepare_bulletin_preview
    @bulletin_copy = @bulletin.bulletin_copies.build(:debate_ids => @bulletin.featured_debate_ids)
    @trackable = false
    @web_version = true
    @preview = render_to_string :template => "/bulletin_mailer/copy", :layout => 'bulletin_mailer'
  end

  def get_candidates
    # debates no incluidos en otros boletines o que aunque hayan sido incluidos tengan la marca correspondiente de destacado para boletin 
    # (probablemente puesta a mano desde /admin/debates/<id>/common)
    debates_included_in_previous_bulletins = Bulletin.where("sent_at IS NOT NULL").select("distinct featured_debate_ids").collect(&:featured_debate_ids).flatten
    conditions = debates_included_in_previous_bulletins.length == 0 ? nil : "id NOT IN (#{debates_included_in_previous_bulletins.join(', ')})"
    @debate_candidates = (Debate.featured_bulletin + Debate.published.translated.current.where(conditions).reorder("published_at DESC")).uniq
    if @bulletin.new_record?
      @candidates = News.featured_bulletin
    else
      if @bulletin.programmed?
        prepare_bulletin_preview
      else
        # Si ya lo habíamos configurado, se las mostramos en el orden en el que las habíamos puesto
        @candidates = @bulletin.bulletin_copies.new.ordered_featured_news + News.featured_bulletin.to_a.delete_if {|n| @bulletin.featured_news_ids.include?(n.id)}
      end
    end
  end

  def bulletin_params
    params.require(:bulletin).permit(:featured_news_ids => [], :featured_debate_ids => [])
  end

end
