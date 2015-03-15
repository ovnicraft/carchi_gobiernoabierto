require 'test_helper'

class JournalistTest < ActiveSupport::TestCase
  test "should not have empty email" do
    user = Journalist.new(:name => "name")
    should_not_be_empty(user, :email)
  end
  
  test "twitter user could have empty password" do
    user = Journalist.new(:name => "name")
    user.save
    assert_equal true, user.errors[:password].empty?
  end
  
  test "should not have empty name" do
    user = Journalist.new(:email => "mail@example.com")
    should_not_be_empty(user, :name)
  end
  
end
