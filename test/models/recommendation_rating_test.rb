require 'test_helper'

class RecommendationRatingTest < ActiveSupport::TestCase

  test "should not create if target not exists" do
  	news = documents(:one_news)

  	recommendation_rating =RecommendationRating.new(:source_type => 'Document', :source_id => news.id, :target_type => 'Document', :target_id => 1000, :user_id => 1, :rating => 1)
  	assert_equal false, recommendation_rating.save  	
  end	

  test "should create reciprocal" do
  	news = documents(:one_news)
  	order = orders(:order_one)
  	assert_difference 'RecommendationRating.count', +2 do
  		recommendation_rating =RecommendationRating.new(:source_type => 'Document', :source_id => news.id, :target_type => 'Order', :target_id => order.id, :user_id => 1, :rating => 1)
  		recommendation_rating.create_reciprocal = true
  		assert_equal true, recommendation_rating.save  	
  	end
  end

  test "should not create reciprocal" do
  	news = documents(:one_news)
  	order = orders(:order_one)
  	assert_difference 'RecommendationRating.count', +1 do
  		recommendation_rating =RecommendationRating.new(:source_type => 'Document', :source_id => news.id, :target_type => 'Order', :target_id => order.id, :user_id => 1, :rating => 1)
  		assert_equal true, recommendation_rating.save  	
  	end
  end

end
