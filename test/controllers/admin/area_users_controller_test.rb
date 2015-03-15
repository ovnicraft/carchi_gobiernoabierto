require 'test_helper'

class Admin::AreaUsersControllerTest < ActionController::TestCase

  test "politician is assigned to area" do
    politician = users(:politician_one)
    area = areas(:a_interior)
    
    assert !politician.areas.include?(area)
    
    login_as(:superadmin)
    assert_difference "AreaUser.count", 1 do
      post :create, :area_id => area.id, :area_user => {:name_and_email => "#{politician.public_name} (#{politician.email})"}
    end
    
    politician.reload
    assert politician.areas.include?(area)
  end

  test "users which is not a politician is not assigned to area" do
    user = users(:jefe_de_prensa)
    area = areas(:a_interior)
    
    login_as(:superadmin)
    assert_no_difference "AreaUser.count" do
      post :create, :area_id => area.id, :area_user => {:name_and_email => "#{user.public_name} (#{user.email})"}
    end
  end
  
  test "user without email is not assigned to area" do
    politician = users(:politician_one)
    area = areas(:a_interior)
    
    assert !politician.areas.include?(area)
    
    login_as(:superadmin)
    assert_no_difference "AreaUser.count" do
      post :create, :area_id => area.id, :area_user => {:name_and_email => "#{politician.public_name}"}
    end
    
    assert flash[:error].match("email")
    
  end
  
end
