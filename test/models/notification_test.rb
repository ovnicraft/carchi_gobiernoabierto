require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  should belong_to :user
  # should validate_uniqueness_of(:user_id).scoped_to(:item_id, :item_type, :read_at)
end
