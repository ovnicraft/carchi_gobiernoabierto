# Clase para los comentarios en cualquiera de los recursos disponibles:
# noticias, propuestas, videos...
class Comment < ActiveRecord::Base
  include Floki
  # belongs_to :document, :counter_cache => true
  belongs_to :commentable, :polymorphic => true, :counter_cache => true
  belongs_to :user
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"
  has_many :ratings, :as => :rateable, :dependent => :destroy

  scope :approved, -> { where("comments.status in ('aprobado', 'aprobado tras denuncia')").order('comments.created_at')}
  scope :pending, -> { where("comments.status = 'pendiente'").order('comments.created_at DESC') }
  scope :approved_or_pending_for, ->(*args) {where(["comments.status in ('aprobado', 'aprobado tras denuncia') OR (comments.status='pendiente' AND user_id=?)", args.first]).order('comments.created_at')}

  # scope :tagged_with, ->(tag_name_es) { includes(commentable: :tags).where("tags.sanitized_name_es IN ('#{tag_name_es}')")}

  scope :official, -> { where(["is_official=?", true])}
  scope :from_twitter, -> {where(["user_id=?", User.irekia_robot ? User.irekia_robot.id : 0])}

  # ###
  # These scopes are meant to be used in Comment class, not in a a comment instace
  scope :local, -> {where(["commentable_type != ?", "ExternalComments::Item"])}
  scope :external, -> {where(["commentable_type = ?", "ExternalComments::Item"])}
  scope :external_and_irekia_for, ->(external_comments_item_ids, irekia_news_id) { where(["((commentable_type = 'ExternalComments::Item') AND
                      (commentable_id in (#{external_comments_item_ids.join(",")})))
                    OR ((commentable_type = 'Document') AND (commentable_id = #{irekia_news_id}))"]).order("comments.created_at DESC")}

  scope :external_for, ->(external_comments_item_ids) { where("((commentable_type = 'ExternalComments::Item') AND
                      (commentable_id in (#{external_comments_item_ids.join(",")})))").order("comments.created_at DESC")}
                      #
  # Comentarios en documentos con +organization_id+ en la lista de +organiztion_ids+
  scope :in_organizations, ->(organization_ids) { joins("INNER JOIN documents ON (comments.commentable_id=documents.id AND commentable_type='Document')").where("documents.organization_id in (#{organization_ids.join(',')})")}

  # Comentarios en páginas externas con +cliente_id+ dentro de la lista +client_ids+
  scope :in_clients, ->(client_ids) { joins("INNER JOIN external_comments_items ON (comments.commentable_id=external_comments_items.id AND commentable_type='ExternalComments::Item')").where("external_comments_items.client_id IN (#{client_ids.join(', ')})")}

  # Comentarios en documentos con +organization_id+ en la lista de +organiztion_ids+
  # y en páginas externas con +cliente_id+ dentro de la lista +client_ids+
  scope :in_organizations_and_clients, ->(organization_ids, client_ids) {joins("LEFT OUTER JOIN documents ON (comments.commentable_id=documents.id AND commentable_type='Document')
               LEFT OUTER JOIN external_comments_items ON (comments.commentable_id=external_comments_items.id AND commentable_type='ExternalComments::Item')").where("documents.organization_id in (#{organization_ids.join(',')}) OR external_comments_items.client_id IN (#{client_ids.join(', ')})")}
  # / These scopes are meant to be used in Comment class, not in a a comment instace
  # ###

  validates_presence_of :user, :name, :body
  validates_presence_of :email, :unless => Proc.new {|c| c.user && c.user.is_outside_user?}
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :unless => Proc.new {|c| c.user && c.user.is_outside_user?}
  validates_format_of :url, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix , :message => I18n.t('comments.blog_url_incorrect'), :allow_blank => true
  # validates_format_of :url, :with => URI::regexp(%w(http https)), :allow_blank => true

  # Para poder asignarle tag de área
  acts_as_ordered_taggable
  # Para poder saber el área de un comentario
  include Tools::WithAreaTag

  attr_accessor :send_reject_email

  # Indica si un comentario está aprobado
  def approved?
    status.eql?('aprobado') || status.eql?('aprobado tras denuncia')
  end

  # Indica si un comentario está rechazado
  def rejected?
    status.eql?('rechazado')
  end

  # Indica si un comentario es spam
  def spam?
    status.eql?('spam')
  end

  # Indica si un comentario está pendiente de aprobación
  def pending?
    status.eql?('pendiente')
  end

  # Indica si un comentario ha sido denunciado
  def abused?
    status.eql?('denunciado')
  end

  before_validation :set_user_name_and_email
  before_validation :nullify_url_if_necessary
  before_create :set_comment_locale
  # before_save :check_abuse_counter

  # Akismet
  # Based in: http://railscasts.com/episodes/65-stopping-spam-with-akismet
  before_create :check_for_spam
  before_create :assign_parents_area

  # preserve this order
  before_create :assign_is_official
  before_create :approve_if_official_commenter
  # / preserve this order

  after_create :notify_official_comments
  after_save    :update_stats_counter
  after_destroy :update_stats_counter

  include Notifiable
  include ExceptionRescuer

  def request=(request) # :nodoc:
    self.user_ip    = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer   = request.env['HTTP_REFERER']
  end


  # Atributos necesarios para que Akismet determine si es spam
  def akismet_attributes # :nodoc:
    {
      :key                  => Rails.application.secrets["akismet_key"],
      :blog                 => "http://#{ActionMailer::Base.default_url_options[:host]}",
      :user_ip              => user_ip,
      :user_agent           => user_agent,
      :comment_author       => name,
      :comment_author_email => email,
      :comment_author_url   => url,
      :comment_content      => body
    }
  end

  # Marca el comentario como spam, comunicándoselo a Akismet
  def mark_as_spam!
    update_attributes(:status => 'spam')
    Akismetor.submit_spam(akismet_attributes) if Rails.application.secrets["akismet_key"]
  end

  # Marca el comentario como no-spam, comunicándoselo a Akismet
  def mark_as_ham!
    update_attributes(:status => 'aprobado')
    Akismetor.submit_ham(akismet_attributes) if Rails.application.secrets["akismet_key"]
  end
  # / Akismet

  def approve!(params={})
    self.update_attributes(:status => 'aprobado')
  end

  def approve_after_abuse!
    self.update_attributes(:status => 'aprobado tras denuncia')
  end

  def reject!
    self.update_attributes(:status => 'rechazado')
    if self.send_reject_email
      email = Notifier.comment_rejected(self)
      email_exception {email.deliver}
    else
      return true
    end
  end

  # Devuelve el nombre del autor del comentario
  def author_name
    self.name || self.user.public_name
  end

  def published_at
    created_at
  end

  def get_commentable
    # HQ
    begin
      item = self.commentable
    rescue ActiveRecord::SubclassNotFound  => err
      if err.to_s.match(/The single-table inheritance mechanism failed to locate the subclass: 'Question'/)
        logger.info "Hiding comment on question #{self.commentable_id}"
      end
      item = nil
    end
    return item
  end

  protected
    # Copia el nombre, el email y la url del comentarista de los datos de usuario. Se llama en before_validation.
    # Hay dos casos especiales:
    # * El comentario se ha importado automáticamente desde Twitter: en este caso el email es común para todos
    #   (User.irekia_robot.email) y el nombre es el nick de twitter
    # * El comentarista se ha loggeado con las credenciales de Twitter o Facebook, y por lo tanto no tenemos su email
    #
    def set_user_name_and_email
      if user
        self.name = self.user.public_name if self.name.blank?
        self.email = self.user.email
        self.url = self.user.url if self.url.blank?
      end
    end

    # El valor por defecto del campo "url" en el formuario es "http://". No es una URL válida, por lo que si se deja asi se vacía.
    # Se llama before_validation
    def nullify_url_if_necessary
      self.url = nil if self.url.eql?("http://")
    end

    # Especifica el idioma del comentario a partir del idioma en el que navega el comentarista,
    # para poder mostrar en cada idioma sólo los comentarios en ese mismo idioma.
    def set_comment_locale
      self.locale = I18n.locale.to_s
    end

    # Aprueba automáticamente el comentario, si es que lo ha hecho un usuario miembro del "staff".
    # Se llama desde before_create
    def approve_if_official_commenter
      self.status = 'aprobado' if self.is_official?
    end

    # Marca el comentario como "denunciado", y por tanto desaparece de la web, cuando ha habido 5 denuncias o más.
    # Se llama desde before_save.
    def check_abuse_counter
      if self.abuse_counter >= 5 && !self.status.eql?('aprobado tras denuncia')
        self.status = 'denunciado'
      end
    end

    # Envía el comentario a Akismet, quien determina si es spam o no
    def check_for_spam
      if Rails.application.secrets['akismet_key'] && Akismetor.spam?(akismet_attributes)
        self.status = 'spam'
      else
        return true
      end
    end

    def assign_parents_area
      self.tag_list = self.commentable.area_tags if self.commentable.respond_to?(:area_tags)
    end

    def assign_is_official
      if self.user_id && self.user.is_official_commenter?
        self.is_official = true
      end
      return true
    end

    def notify_official_comments
      if self.is_official?
        if self.commentable.is_a?(Proposal)
          participants = ([self.commentable.author] + self.commentable.commenters + self.commentable.argumenters - [self.author]).uniq
          participants.each do |participant|
            if participant.email.present?
              notification = Notifier.proposal_answer(self.commentable, participant)
              email_exception { notification.deliver }
            end
          end
        else
          participants = self.commentable.commenters - [self.author]
          participants += self.commentable.argumenters if self.commentable.is_a?(Debate)
          participants.uniq.each do |participants|
            if participants.email.present?
              notification = Notifier.comment_answer(self, participants)
              email_exception { notification.deliver }
            end
          end
        end
      end
    end


    def update_stats_counter
      if self.commentable.respond_to?(:stats_counter)
        stats_info = self.commentable.stats_counter || self.commentable.build_stats_counter
        stats_info.comments = self.commentable.comments.approved.count
        stats_info.official_comments = self.commentable.comments.official.approved.count
        stats_info.user_comments = stats_info.comments - stats_info.official_comments
        stats_info.twitter_comments = self.commentable.comments.from_twitter.approved.count
        stats_info.not_twitter_comments = stats_info.user_comments - stats_info.twitter_comments

        if self.commentable.is_a?(Proposal) && self.is_official? && stats_info.answer_time_in_seconds.blank?
          stats_info.answer_time_in_seconds = (self.created_at - self.commentable.published_at).to_i
        end
        stats_info.save!
      end
    end
end
