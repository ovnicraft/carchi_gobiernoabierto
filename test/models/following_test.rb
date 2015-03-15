require 'test_helper'

class FollowingTest < ActiveSupport::TestCase
  
  test "validate presence of user" do
    area = areas(:a_lehendakaritza)
    following = Following.new(:followed_id => area.id, :followed_type => 'Area')
    assert_equal false, following.save
    assert_equal ['no puede estar vacío'], following.errors[:user_id]
  end  
  
  test "validates presence of followed item" do
    user = users(:person_follows)
    following = Following.new(:user_id => user.id)
    assert_equal false, following.save
    assert_equal ['no puede estar vacío'], following.errors[:followed_id]
    assert_equal ['no puede estar vacío'], following.errors[:followed_type]
  end  
  
  test "valid following" do
    user = users(:person_follows)
    area = areas(:a_lehendakaritza)
    following = Following.new(:followed_id => area.id, :followed_type => 'Area', :user_id => user.id)
    assert_equal true, following.save
    assert_equal user, following.user
    assert_equal area, following.followed
  end  
  
  test "politician follows area" do
    user = users(:politician_one)
    area = areas(:a_lehendakaritza)
    following = Following.new(:followed_id => area.id, :followed_type => 'Area', :user_id => user.id)
    assert_equal true, following.save
  end  
  
end  