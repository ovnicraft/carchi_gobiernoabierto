require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  test "should not have empty email" do
    user = Person.new(:name => "name")
    should_not_be_empty(user, :email)
  end
  
  test "should not have empty password" do
    user = Person.new(:name => "name")
    should_not_be_empty(user, :password)
  end
  
  test "should not have empty name" do
    user = Person.new(:email => "mail@example.com")
    should_not_be_empty(user, :name)
  end
  
  test "twitter user could have empty email" do
    user = Person.new(:screen_name => "screenname", :name => "name")
    user.save
    assert_empty user.errors[:email]
  end
  
  test "twitter user could have empty password" do
    user = Person.new(:screen_name => "screenname", :name => "name")
    user.save
    assert_empty user.errors[:password]
  end
  
  test "twitter user should not have empty name" do
    user = Person.new(:screen_name => "screen_name")
    should_not_be_empty(user, :name)
  end
  
  test "twitter user is approved by default" do
    user = Person.new(:screen_name => "screen_name", :name => "name")
    user.save
    assert user.errors
    assert_equal "aprobado", user.status
  end
  
  test "twitter_user cannot use another users email" do
    user = users(:twitter_user)
    user.email = users(:admin).email
    assert !user.save
    assert user.errors[:email].include?("ya existe un usuario con este email")
  end


  test "facebook user could have empty email" do
    user = Person.new(:name => "Nuevo usuario desde Facebook", :fb_id => '123')
    user.save
    assert_empty user.errors[:email]
  end
  
  test "facebook user could have empty password" do
    user = Person.new(:name => "Nuevo usuario desde Facebook", :fb_id => '123')
    user.save
    assert_empty user.errors[:password]
  end
  
  test "facebook user should not have empty name" do
    user = Person.new(:fb_id => '123')
    should_not_be_empty(user, :name)
  end
  
  test "facebook user is approved by default" do
    user = Person.new(:fb_id => "123", :name => "name")
    user.save
    assert user.errors
    assert_equal "aprobado", user.status
  end
  
  test "facebook_user cannot use another users email" do
    user = users(:facebook_user)
    user.email = users(:admin).email
    assert !user.save
    assert user.errors[:email].include?("ya existe un usuario con este email")
  end
  
  test "should has many followings" do
    user = users(:person_follows)
    area = areas(:a_lehendakaritza)
    politician = users(:politician_one)
    following_area = Following.new(:followed_id => area.id, :followed_type => 'Area', :user_id => user.id)
    assert_equal true, following_area.save
    following_politician = Following.new(:followed_id => politician.id, :followed_type => 'Politician', :user_id => user.id)
    assert_equal true, following_politician.save

    assert_equal 2, user.followings.size
    assert_equal [area], user.following_areas
    assert_equal [politician], user.following_politicians
  end  

  test "should assign geo location" do
    person = users(:visitante)
    
    person.raw_location = "Gran Via 1, Bilbao"
    assert person.save
    assert person.lat
    assert person.lng
  end  
end
