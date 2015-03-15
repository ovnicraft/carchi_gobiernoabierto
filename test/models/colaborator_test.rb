require 'test_helper'

class ColaboratorTest < ActiveSupport::TestCase
  test "should not have empty email" do
    user = Colaborator.new(:name => "name")
    should_not_be_empty(user, :email)
  end
  
  test "should not have empty password" do
    user = Colaborator.new(:name => "name")
    should_not_be_empty(user, :password)
  end
  
  test "should not have empty name" do
    user = Colaborator.new(:email => "mail@example.com")
    should_not_be_empty(user, :name)
  end
  
end
