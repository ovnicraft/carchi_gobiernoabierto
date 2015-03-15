require 'active_support/concern'

module ActsAsCommentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, -> { order("comments.created_at DESC") }, :as => :commentable, :dependent => :destroy
    has_one :stats_counter, :class_name => "::Stats::Counter", :as => :countable, :dependent => :destroy

    after_save :update_department_organization_and_area_in_stats_counters
  end

  def commenters
    self.comments.collect {|c| c.user}.uniq
  end

  def update_department_organization_and_area_in_stats_counters
    counter = self.stats_counter || self.build_stats_counter

    if self.respond_to?(:organization_id_changed?) && self.organization_id_changed?
      counter.organization_id = self.organization_id
      counter.department_id = self.department.id
    end
    if self.respond_to?(:area_changed?) && self.area_changed?
      counter.area_id = self.area_id
    end
    logger.info "going to save"
    counter.save
  end


  module ClassMethods

  end
end
