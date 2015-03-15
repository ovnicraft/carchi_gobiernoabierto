class Bulletin < ActiveRecord::Base

  CONTENT_TYPES = {'d' => 'Debate', 'n' => 'News', 'b' => 'BulletinCopy'}
  # LOGO = "logo.png"
  TRACKING_IMAGE = "euskadi_net_logo.png"
  MAX_FEATURED_NEWS = 3
  MAX_USER_NEWS = 4

  AVAILABLE_LANGUAGES = AvailableLocales::AVAILABLE_LANGUAGES.except(:en)

  serialize :featured_news_ids, Array
  serialize :featured_debate_ids, Array
  translates :title

  validate :max_featured_news
  def max_featured_news
    if self.featured_news_ids.length > MAX_FEATURED_NEWS
      self.errors.add :featured_news_ids, "El máximo de noticias destacadas es #{MAX_FEATURED_NEWS}"
    end
  end

  has_many :bulletin_copies, :dependent => :destroy
  has_many :openings, :through => :bulletin_copies
  has_many :clicks_from, :through => :bulletin_copies

  scope :sent, -> { where("sent_at IS NOT NULL").order("sent_at")}
  scope :unsent, -> { where("sent_at IS NULL")}
  scope :pending, -> { where("sent_at IS NULL AND send_at IS NOT NULL")}

  before_save :ensure_featured_news_and_debates_are_integers
  before_save :set_default_values

  def self.subscribers
    User.approved.wants_bulletin
  end
  
  # Lists all news featured in previous bulletins
  def self.sent_featured_news
    self.sent.select("featured_news_ids").collect(&:featured_news_ids).flatten
  end

  def programmed?
    self.sent_at.blank? && self.send_at.present?
  end

  def unique_user_openings
    self.openings.select(:user_id).distinct.count
  end

  private
  def ensure_featured_news_and_debates_are_integers
    self.featured_news_ids = self.featured_news_ids.collect(&:to_i) - [0]
    self.featured_debate_ids = self.featured_debate_ids.collect(&:to_i) - [0]
  end

  def set_default_values
    now = Time.zone.now
    # self.featured_news_ids = News.featured_bulletin.collect(&:id) if self.featured_news_ids.blank? && News.featured_bulletin.length > 0
    # self.featured_debate_ids = Debate.featured_bulletin.collect(&:id) if self.featured_debate_ids.blank? && Debate.featured_bulletin.length > 0
    # self.sent_at = now if self.sent_at.blank?
    self.title_es = I18n.l(now.to_date, :locale => 'es', :format => :long) if self.title_es.blank?
    self.title_eu = I18n.l(now.to_date, :locale => 'eu', :format => :long) if self.title_eu.blank?
    self.title_en = I18n.l(now.to_date, :locale => 'en', :format => :long) if self.title_en.blank?
  end
end
