class TwitterMention < ActiveRecord::Base
  def self.last
    order("tweet_published_at DESC").first
  end
end
