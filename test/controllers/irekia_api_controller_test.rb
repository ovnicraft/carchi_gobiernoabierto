require 'test_helper'

class IrekiaApiControllerTest < ActionController::TestCase

  test "should return tags list" do
    get :tags, format: :json
    assert_response :success
  end
  
  test "should return the photos path for a specified news id" do
    document = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)
    assert document.photos
    
    get :photos, :id => document.id, format: :json
    assert_response :success
    assert assigns(:photos)        
  end

  test "should return the videos data for a specified news id" do
    document = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)
    assert document.photos
    
    get :videos, :id => document.id, format: :json
    assert_response :success    
    assert assigns(:videos)
  end
    
end
