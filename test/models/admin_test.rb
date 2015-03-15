require 'test_helper'

class AdminTest < ActiveSupport::TestCase
  test "should not have empty email" do
    user = Admin.new(:name => "name")
    should_not_be_empty(user, :email)
  end
  
  test "should not have empty password" do
    user = Admin.new(:name => "name")
    should_not_be_empty(user, :password)
  end
  
  test "should not have empty name" do
    user = Admin.new(:email => "mail@example.com")
    should_not_be_empty(user, :name)
  end

  context "existing admin" do
    setup do
      @admin = Admin.new(:email => "admin@example.com", :name => "Pepe", :password => "test", :password_confirmation => "test")
      @admin.save
    end
    
    should "have proposal edition permission" do
      assert @admin.can_edit?('proposals')
    end
  end  
end
