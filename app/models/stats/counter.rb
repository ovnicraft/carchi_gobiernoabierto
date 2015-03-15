class Stats::Counter < ActiveRecord::Base
  belongs_to :countable, :polymorphic => true

  before_save :set_area_organization_and_department
  def set_area_organization_and_department
    self.countable_subtype = self.countable.class.to_s
    self.published_at = self.countable.respond_to?(:published_at) ? self.countable.published_at : self.countable.created_at
    self.area_id = self.countable.area_id if self.countable.respond_to?(:area_id) && self.area_id.blank?
    if self.countable.respond_to?(:organization_id)
      self.organization_id = self.countable.organization_id if self.organization_id.blank?
      self.department_id = self.countable.department.id if self.department_id.blank? && self.countable.department.present?
    end
  end

  def recount
    if self.countable.respond_to?(:organization_id)
      self.organization_id = self.countable.organization_id 
      self.department_id = self.countable.department.id if self.countable.department
    end
    if self.countable.respond_to?(:area_tags)
      self.area_id = self.countable.area.id if self.countable.area
    end
    self.comments = self.countable.comments.approved.count
    self.official_comments = self.countable.comments.official.approved.count
    self.user_comments = self.comments - self.official_comments
    self.twitter_comments = self.countable.comments.from_twitter.approved.count
    self.not_twitter_comments = self.user_comments - self.twitter_comments

    if [News, Proposal].include?(self.countable.class)
      self.answer_time_in_seconds = (self.countable.comments.official.last.created_at - self.countable.published_at).to_i if self.countable.comments.official.length > 0
    end

    if [Proposal, Debate].include?(self.countable.class)
      self.votes = self.countable.votes.count
      self.positive_votes = self.countable.votes.positive.count
      self.negative_votes = self.countable.votes.negative.count

      self.arguments = self.countable.arguments.count
      self.in_favor_arguments = self.countable.arguments.in_favor.count
      self.against_arguments = self.countable.arguments.against.count
    end
  end
end
