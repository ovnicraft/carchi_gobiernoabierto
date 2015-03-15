class Argument < ActiveRecord::Base
  include Floki

  belongs_to :argumentable, :polymorphic => true, :counter_cache => true

  belongs_to :user
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"

  scope :in_favor, -> { where("value = 1")}
  scope :against, -> { where("value = -1")}
  scope :pending, -> { where("published_at IS NULL").order("created_at DESC")}
  scope :published, ->(*args) { where(["arguments.published_at <= ?", (args.first || Time.zone.now)])}
  scope :rejected, ->(*args) { where(["rejected_at <= ?", (args.first || Time.zone.now)])}

  scope :for_debates,   -> { where("argumentable_type='Debate'")}
  scope :for_proposals, -> { where("argumentable_type='Proposal'")}

  validates_length_of :reason, :maximum => 255

  include Notifiable

  def approved?
    !published_at.blank?
  end

  def status
    published_at.nil? ? 'pendiente' : 'aprobado'
  end

  def approve!(params={})
    self.update_attributes(:published_at => Time.zone.now)
  end

  def reject!
    self.destroy
  end

  def in_favor
    value == 1
  end

  def body
    self.reason
  end

  def author_name
    self.user.public_name if self.user
  end

  before_create :approve_if_admin
  after_save    :update_stats_counter
  after_destroy :update_stats_counter

  private
    def approve_if_admin
      if self.user_id
        if User.find(self.user_id).is_staff?
          self.published_at = Time.zone.now if self.published_at.nil?
        end
      end
    end

    def update_stats_counter
      if self.argumentable.respond_to?(:stats_counter)
        stats_info = self.argumentable.stats_counter || self.argumentable.build_stats_counter
        stats_info.arguments = self.argumentable.arguments.published.count
        stats_info.in_favor_arguments = self.argumentable.arguments.published.in_favor.count
        stats_info.against_arguments = self.argumentable.arguments.published.against.count
        stats_info.save
      end
    end
end
