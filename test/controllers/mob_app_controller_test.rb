require 'test_helper'

class MobAppControllerTest < ActionController::TestCase
  
  test "should validate appdata" do
    get :appdata, :v => 3, :locale => "es"
    response = JSON.parse(@response.body)
  end

  test "should validate root controller" do
    get :root, :locale => "es"
    response = JSON.parse(@response.body)
  end
  
  test "consejo news should not be in iphone version" do
    get :news, :format => "json"
    assert assigns(:news).length > 0
    assert !assigns(:news).include?(documents(:consejo_news))
    response = JSON.parse(@response.body)
  end

  test "should show all news" do
    get :news, :format => "json"
    assert_response :success
    
    assert assigns(:news).length > 0
    assert assigns(:news).map {|n| n.area_id}.uniq.length > 1
    response = JSON.parse(@response.body)
  end

  test "should show area news" do
    get :news, :area_id => areas(:a_lehendakaritza).id, :format => "json"
    assert_response :success
    
    assert assigns(:news).length > 0
    assert_equal [areas(:a_lehendakaritza).id], assigns(:news).map {|n| n.area_id}.uniq
    response = JSON.parse(@response.body)
  end

  test "should show all videos" do
    get :videos, :format => "json"
    assert_response :success
    
    assert assigns(:videos).length > 0
    assert assigns(:videos).map {|n| n.area_id}.uniq.length > 1
    response = JSON.parse(@response.body)
  end

  test "should show area videos" do
    get :videos, :area_id => areas(:a_lehendakaritza).id, :format => "json"
    assert_response :success
    
    assert assigns(:videos).length > 0
    assert_equal [areas(:a_lehendakaritza).id], assigns(:videos).map {|n| n.area_id}.uniq
    response = JSON.parse(@response.body)
  end

  test "should show photos" do
    get :photos, :format => "json"
    assert_response :success
    
    assert assigns(:photos).length > 0
    assert assigns(:photos).map {|n| n.area_id}.uniq.length > 1
    response = JSON.parse(@response.body)
  end

  test "should show area photos" do
    get :photos, :area_id => areas(:a_lehendakaritza).id, :format => "json"
    assert_response :success
    
    assert assigns(:photos).length > 0
    assert_equal [areas(:a_lehendakaritza).id], assigns(:photos).map {|n| n.area_id}.uniq
    response = JSON.parse(@response.body)
  end

 if Settings.optional_modules.proposals
  test "should show proposals" do
    get :proposals, :format => "json"
    assert_response :success
    
    assert assigns(:proposals).length > 0
    assert assigns(:proposals).map(&:area).map(&:id).uniq.length > 1
    response = JSON.parse(@response.body)
  end
  
  test "should show area proposals" do
    get :proposals, :area_id => areas(:a_lehendakaritza).id, :format => "json"
    assert_response :success
    
    assert assigns(:proposals).length > 0
    assert_equal [areas(:a_lehendakaritza).id], assigns(:proposals).map(&:area).map(&:id).uniq
    response = JSON.parse(@response.body)
  end
 end
  
  test "should show argazki" do
    get :argazki, :format => "json"
    assert_response :success    
    # assert assigns(:photos).length > 0
    # 
    # response = JSON.parse(@response.body)
  end
  
  
end
