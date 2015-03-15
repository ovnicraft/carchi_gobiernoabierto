class CreateRecommendationRatings < ActiveRecord::Migration
  def self.up
    create_table :recommendation_ratings do |t|
      t.string :source_type, :null => false
      t.integer :source_id, :null => false
      t.string :target_type, :null => false
      t.integer :target_id, :null => false
      t.integer :rating, :null => false
      t.integer :user_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :recommendation_ratings
  end
end
