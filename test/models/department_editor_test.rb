require 'test_helper'

class DepartmentEditorTest < ActiveSupport::TestCase
  test "should not have empty email" do
    user = DepartmentEditor.new(:name => "name")
    should_not_be_empty(user, :email)
  end
  
  test "should not have empty password" do
    user = DepartmentEditor.new(:name => "name")
    should_not_be_empty(user, :password)
  end
  
  test "should not have empty name" do
    user = DepartmentEditor.new(:email => "mail@example.com")
    should_not_be_empty(user, :name)
  end

  context "existing department editor" do
    setup do
      @department_editor = DepartmentEditor.new(:email => "depteditor@example.com", :name => "Pepe", :password => "test", :password_confirmation => "test")
      @department_editor.save
    end
    
    should "have proposal edition permission" do
      assert @department_editor.can_edit?('proposals')
    end
  end
end
