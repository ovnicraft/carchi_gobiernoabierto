class RecommendationRating < ActiveRecord::Base
  validates_presence_of :source_type, :source_id, :target_type, :target_id, :user_id, :rating
  belongs_to :user
  belongs_to :source, :polymorphic => true
  belongs_to :target, :polymorphic => true

  attr_accessor :create_reciprocal

  before_save :check_source_and_target_exists, :should_create_reciprocal

  def create_reciprocal
    @create_reciprocal || false    
  end

  def check_source_and_target_exists
    unless self.source.present? && self.target.present?
      self.errors.add(:base, 'No existe el item destino')
      return false
    end
  end

  def should_create_reciprocal
    if self.create_reciprocal
      RecommendationRating.create(:source_id => self.target_id, :source_type => self.target_type, :target_id => self.source_id, :target_type => self.source_type, :rating => self.rating, :user_id => self.user_id)
    end
  end
end
