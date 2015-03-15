require 'test_helper'

class FollowingsControllerTest < ActionController::TestCase
  
  test "should redirect without logged_in" do
    area = areas(:a_lehendakaritza)
    assert_no_difference 'Following.count' do
      post :create, :following => {:followed_id => area.id, :followed_type => 'Area'}, :locale => 'es'
    end
    assert_response :redirect
    assert_redirected_to new_session_url  
  end  
  
  test "should follow area" do
    login_as("person_follows")
    area = areas(:a_lehendakaritza)
    assert_difference 'Following.count', +1 do
      post :create, :following => {:followed_id => area.id, :followed_type => 'Area'}, :locale => 'es'
    end  
    assert_response :success
    assert_template 'followings/update_all'
  end  
  
  test "should not follow area missing data" do
    login_as("person_follows")
    area = areas(:a_lehendakaritza)
    assert_no_difference 'Following.count' do
      post :create, :following => {:followed_id => area.id}, :locale => 'es'
    end  
    assert_response :error
  end
  
  test "should follow politician" do
    login_as("person_follows")
    politician = users(:politician_one)
    assert_difference 'Following.count', +1 do
      post :create, :following => {:followed_id => politician.id, :followed_type => 'Politician'}, :locale => 'es'
    end  
    assert_response :success
    assert_template 'followings/update_all'
  end  
  
  test "should not follow politician missing data" do
    login_as("person_follows")
    politician = users(:politician_one)
    assert_no_difference 'Following.count' do
      post :create, :following => {:followed_id => politician.id}, :locale => 'es'
    end  
    assert_response :error
  end
  
  test "should unfollow area" do
    login_as("person_follows")
    user = users(:person_follows)
    area = areas(:a_lehendakaritza)
    following = Following.create(:user_id => user.id, :followed_id => area.id, :followed_type => 'Area')
    assert_difference 'Following.count', -1 do
      delete :destroy, :id => following.id, :locale => 'es'
    end  
    assert_response :success
    assert_template 'followings/update_all'
  end  
  
  test "should unfollow politicianxx" do
    login_as("person_follows")
    user = users(:person_follows)
    politician = users(:politician_one)
    following = Following.create(:user_id => user.id, :followed_id => politician.id, :followed_type => 'Politician')
    assert_difference 'Following.count', -1 do
      delete :destroy, :id => following.id, :locale => 'es'
    end  
    assert_response :success
    assert_template 'followings/update_all'
  end
  
  test "should respond with needs_auth json when not logged in" do
    post :create, :locale => 'es', :format => 'floki'
    response = JSON.parse(@response.body)
    assert_equal true, response['needs_auth']
  end
  
  test "should respond with follow json when logged in" do
    login_as("person_follows")
    politician = users(:politician_one)
    assert_difference 'Following.count', +1 do
      post :create, :following => {:followed_id => politician.id, :followed_type => 'Politician'}, :locale => 'es', :format => 'floki'
    end  
    response = JSON.parse(@response.body)
    assert_equal true, response['following']
  end
  
  test "should respond with follow json with errors when logged in" do
    login_as("person_follows")
    politician = users(:politician_one)
    assert_no_difference 'Following.count' do
      post :create, :following => {:followed_type => ''}, :locale => 'es', :format => 'floki'
    end  
    response = JSON.parse(@response.body)
    assert_equal false, response['following']
  end
  
  test "should respond with needs_auth json when not logged in in unfollow" do
    delete :destroy, :locale => 'es', :format => 'floki'
    response = JSON.parse(@response.body)
    assert_equal true, response['needs_auth']
  end

  test "should respond with unfollow json when logged in" do
    login_as("person_follows")
    user = users(:person_follows)
    politician = users(:politician_one)
    following = Following.create(:user_id => user.id, :followed_id => politician.id, :followed_type => 'Politician')
    assert_difference 'Following.count', -1 do
      delete :destroy, :id => following.id, :locale => 'es', :format => 'floki'
    end  
    response = JSON.parse(@response.body)
    assert_equal false, response['following']
  end
  
end