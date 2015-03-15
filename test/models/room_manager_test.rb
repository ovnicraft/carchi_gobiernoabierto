require 'test_helper'

class RoomManagerTest < ActiveSupport::TestCase
  test "should not have empty email" do
    user = RoomManager.new(:name => "name")
    should_not_be_empty(user, :email)
  end
  
  test "should not have empty password" do
    user = RoomManager.new(:name => "name")
    should_not_be_empty(user, :password)
  end
  
  test "should not have empty name" do
    user = RoomManager.new(:email => "mail@example.com")
    should_not_be_empty(user, :name)
  end
  
end
