require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  
  test "should get show" do
    page = documents(:page_in_menu)
    get :show, :id => page.id, :locale => 'es'
    assert_response :success
    assert_template 'pages/show'
  end
  
  test "should track clickthrough when clicking on a search result" do
    assert_content_is_tracked(criterios(:criterio_one), documents(:page_in_menu))
  end
  
  test "should track clickthrough when clicking on a tag item" do
    assert_content_is_tracked(tags(:viajes_oficiales), documents(:page_in_menu))
  end
  
end
