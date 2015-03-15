require 'test_helper'

class Admin::HeadlinesControllerTest < ActionController::TestCase
 if Settings.optional_modules.headlines
  test "should redirect if not logged in" do
    get :index
    assert_not_authorized
  end
  
  test "should redirect if not required permission" do
    login_as('jefe_de_gabinete')
    get :index
    assert_not_authorized
  end

  test "should get #index if admin" do
    login_as("admin")
    get :index
    assert_response :success    
  end             

  test "should get #index if required permission" do
    user = users(:colaborador_externo)
    Permission.create(:user_id => user.id, :module => 'headlines', :action => 'approve')
    login_as("colaborador_externo")
    get :index
    assert_response :success    
  end             
  
  test "should #update headline status" do
    login_as(:admin)    
    hl = headlines(:headline_media)
    xhr :put, :update, :id => hl.id, :headline => {:draft => true}, :format => 'js'
    assert_response :success
  end                       
  
  test "should #update headline area" do
    login_as(:admin)    
    hl = headlines(:headline_media)
    area = areas(:a_lehendakaritza)
    assert_equal nil, hl.area
    xhr :put, :update_area, :id => hl.id, :area_tags => area.area_tag.name_es, :format => 'js'
    assert_response :success                                         
    hl.reload
    assert_equal area, hl.area
  end

  test "should #update headline tag_list" do
    login_as(:admin)    
    hl = headlines(:headline_media)
    assert_equal [], hl.tag_list_without_areas
    assert_difference 'ActsAsTaggableOn::Tagging.count', +1 do
      assert_difference 'ActsAsTaggableOn::Tag.count', +1 do
        xhr :put, :update, :id => hl.id, :build_params => 'true', :tag_list => 'new_tag', :format => 'js'
      end
    end
    assert_response :success                                         
    hl.reload
    assert_equal ['new_tag'], hl.tag_list
  end
  
  test "should #destroy" do
    login_as(:admin)    
    hl = headlines(:headline_media)
    assert_difference 'Headline.count', -1 do
      xhr :delete, :destroy, :id => hl.id, :format => 'js'
    end                                            
    assert_response :success
  end                       
  
  test "should #delete from entzumena" do    
    hl = headlines(:headline_media)                                                                               
    assert_difference 'Headline.count', -1 do
      delete :delete_from_entzumena, :source_item_id => hl.source_item_id, :source_item_type => hl.source_item_type
    end  
    assert_response :success
  end  
 end
end
