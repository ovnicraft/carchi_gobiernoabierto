require 'test_helper'

class ExternalColaboratorTest < ActiveSupport::TestCase
  test "should not have empty email" do
    user = ExternalColaborator.new(:name => "name")
    should_not_be_empty(user, :email)
  end
  
  test "should not have empty password" do
    user = ExternalColaborator.new(:name => "name")
    should_not_be_empty(user, :password)
  end
  
  test "should not have empty name" do
    user = ExternalColaborator.new(:email => "mail@example.com")
    should_not_be_empty(user, :name)
  end

  test "should not have any access" do
    user = users(:colaborador_externo)
    assert_equal false, user.can_access?('news')
  end

  test "should not have admin access" do
    user = users(:colaborador_externo)
    assert_equal false, user.has_admin_access?
  end

  test "should have access to modules and admin" do
    user = users(:colaborador_externo)
    Permission.create(:user_id => user.id, :module => 'headlines', :action => 'approve')
    assert_equal true, user.can?('approve', 'headlines')
    assert_equal true, user.has_admin_access?
  end
  
end
