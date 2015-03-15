class Vote < ActiveRecord::Base
  include Floki
  # belongs_to :proposal

  belongs_to :votable, :polymorphic => true, :counter_cache => true

  belongs_to :user
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"

  validates_inclusion_of :value, :in => [1,-1], :message => I18n.t('votes.invalid')
  validates_uniqueness_of :user_id, :scope => [:votable_type, :votable_id], :message => I18n.t('votes.proposal_already_voted')

  scope :for_prop_from_politicians, -> { where("votable_type='Debate'")}
  scope :for_prop_from_citizens, -> { where("votable_type='Proposal'")}
  scope :active, -> { joins("INNER JOIN proposals on (proposals.id=votes.votable_id and votable_type='Proposal') INNER JOIN organizations ON (proposals.organization_id = organizations.id)").where("organizations.active='t'")}

  scope :positive, -> { where("value=1")}
  scope :negative, -> { where("value=-1")}

  after_save    :update_stats_counter
  after_destroy :update_stats_counter

  include Notifiable

  def approved?
    true
  end

  def positive
    value == 1
  end

  def published_at
    created_at
  end

  private

    def update_stats_counter
      if self.votable.respond_to?(:stats_counter)
        stats_info = self.votable.stats_counter || self.votable.build_stats_counter
        stats_info.votes = self.votable.votes.count
        stats_info.positive_votes = self.votable.votes.positive.count
        stats_info.negative_votes = self.votable.votes.negative.count
        stats_info.save
      end
    end
end
