class ChangeRatingToNumeric < ActiveRecord::Migration
  def self.up
    change_column :recommendation_ratings, :rating, :numeric
    execute "UPDATE recommendation_ratings SET rating = -1 WHERE rating = 0"
  end

  def self.down
    execute "UPDATE recommendation_ratings SET rating = 0 WHERE rating = -1"        
    change_column :recommendation_ratings, :rating, :integer             
  end
end
