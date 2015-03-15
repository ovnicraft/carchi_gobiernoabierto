require 'test_helper'

class StreamingOperatorTest < ActiveSupport::TestCase
  test "should not have empty email" do
    user = StreamingOperator.new(:name => "name")
    should_not_be_empty(user, :email)
  end
  
  test "should not have empty password" do
    user = StreamingOperator.new(:name => "name")
    should_not_be_empty(user, :password)
  end
  
  test "should not have empty name" do
    user = StreamingOperator.new(:email => "mail@example.com")
    should_not_be_empty(user, :name)
  end
  
end
