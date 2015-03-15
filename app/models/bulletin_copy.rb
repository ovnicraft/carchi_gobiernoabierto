class BulletinCopy < ActiveRecord::Base
  belongs_to :user
  belongs_to :bulletin
  
  # Slightly different to Clickthroughable because here we have the concept of opening a bulletin (should not count as click_from)
  # clicks_to: same definition as Clickthroughable and represents clicks on "can't see this email properly?"
  has_many :clicks_to, -> { order("created_at DESC") }, :class_name => "Clickthrough", :foreign_key => "click_target_id", :as => :click_target, :dependent => :destroy
  # clicks_from: source=BulletinCopy and target!=nil
  has_many :clicks_from, -> { where("click_target_type IS NOT NULL").order("created_at DESC") }, :class_name => "Clickthrough", :foreign_key => "click_source_id", :as => :click_source, :dependent => :destroy
  # opening: source=BulletinCopy and target=nil
  has_many :openings, -> { where("click_source_type='BulletinCopy' AND click_target_type IS NULL")}, :class_name => "Clickthrough", :foreign_key => "click_source_id", :dependent => :destroy

  serialize :news_ids, Array
  serialize :debate_ids, Array

  before_save :set_news_ids
  before_save :set_debate_ids
  after_save :send_by_email

  # def ordered_news
  #   news_by_date = News.published.find(self.news_ids)
  #   ordered_news = news_by_date.sort {|a, b| self.news_ids.index(a.id) <=> self.news_ids.index(b.id)}
  #   return ordered_news
  # end

  # We want news in the same order we queried them
  def ordered_featured_news
    pre_news_ids = self.bulletin.featured_news_ids

    # Hack para que funcione el link al mensaje del Lehendakari que han
    # enviado en el boletin y que al parecer han sustituido por otra noticia a posteriori
    news_ids = []
    pre_news_ids.each do |nid|
      news_ids << (nid == 17404 ? 17405 : nid)
    end

    news_by_date = News.published.find(news_ids)
    featured_news = news_by_date.sort {|a, b| news_ids.index(a.id) <=> news_ids.index(b.id)}
    return featured_news
  end

  # We want news in the same order we queried them
  def ordered_user_news
    news_ids = self.news_ids
    if news_ids.length > 0
      news_by_date = News.published.where("id in (#{news_ids.join(', ')})")
      user_news = news_by_date.sort {|a, b| news_ids.index(a.id) <=> news_ids.index(b.id)}
      return user_news
    else
     return []
    end
  end

  # We want news in the same order we queried them
  def ordered_debates
    debates_by_date = Debate.published.find(self.debate_ids)
    ordered_debates = debates_by_date.sort {|a, b| self.debate_ids.index(a.id) <=> self.debate_ids.index(b.id)}
    return ordered_debates
  end

  def sent?
    self.sent_at.present?
  end

  private
  def set_news_ids
    self.news_ids = self.user.news_for_bulletin(self.bulletin_id)
  end

  def set_debate_ids
    self.debate_ids = self.bulletin.featured_debate_ids
  end

  def send_by_email
    begin
      I18n.with_locale self.user.alerts_locale do
        BulletinMailer.copy(self).deliver
      end
    rescue => err_type
      self.errors.add(:sent_at, "There were some errors sending event alert: #{err_type}")
      logger.info("\tThere were some errors sending event alert: " + err_type.to_s)
      self.destroy
      return false
    else
      self.update_column(:sent_at, Time.zone.now)
      self.user.update_attributes(:bulletin_sent_at => Time.zone.now)
    end
  end

end
