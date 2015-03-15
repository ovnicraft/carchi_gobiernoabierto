require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  
  test "should get shoy by no orden" do
    order = orders(:order_one)
    get :show, :no_orden => order.no_orden, :locale => 'es'
    assert_response :success
    assert_template 'orders/show'
    assert assigns(:order)
  end            
  
  test "should get show and highlight according to criterio" do
    criterio = criterios(:criterio_one)
    order = orders(:order_one)
    get :show, :no_orden => order.no_orden, :criterio_id => criterio.id, :locale => 'es'
    assert_response :success
    assert_template 'orders/show'
    assert assigns(:order)
    assert assigns(:criterio)    
    assert_select 'div.text span.highlight', "noticia"
  end  
  
  test "should post search keyword" do
    assert_difference 'Criterio.count', +1 do
      post :search, :key => 'keyword', :value => 'LEY 2000'
    end
    criterio = Criterio.last
    assert_response :redirect                         
    assert_redirected_to search_url(:id => criterio.id)    
    assert_equal "type: orders AND keyword: \"LEY 2000\"", criterio.title
    assert_equal true, criterio.only_title
  end                                     
  
  test "should post search materias" do
    assert_difference 'Criterio.count', +1 do
      post :search, :key => 'materias', :value => 'Personal'
    end
    criterio = Criterio.last
    assert_response :redirect                         
    assert_redirected_to search_url(:id => criterio.id, :sort => 'date')  
    assert_equal "type: orders AND materias: Personal", criterio.title    
    assert_equal false, criterio.only_title
  end
  
  test "should track clickthrough when clicking on a related item" do
    source = documents(:commentable_news)
    target = orders(:order_one)
    assert_order_is_tracked(source, target)
  end
  
  test "should track clickthrough when clicking on a related order" do
    source = orders(:order_two)
    target = orders(:order_one)
    assert_order_is_tracked(source, target)
  end
  
  test "should track clickthrough when clicking on a search result" do
    source = criterios(:criterio_one)
    target = orders(:order_one)
    assert_order_is_tracked(source, target)
  end
  
  test "should track clickthrough when clicking on a tag item" do
    source = tags(:viajes_oficiales)
    target = orders(:order_one)
    assert_order_is_tracked(source, target)
  end


  def assert_order_is_tracked(source, target)
    if source.is_a?(Order)
      @request.env["HTTP_REFERER"] = order_url(source.no_orden)
    elsif source.is_a?(Criterio)
      @request.env["HTTP_REFERER"] = search_url(source)
    else      
      @request.env["HTTP_REFERER"] = send("#{source.class.to_s.downcase.split('::').last}_url", :id => source.to_param)
    end

    assert_difference 'Clickthrough.count', +1 do
      get :show, :no_orden => target.no_orden, :track => 1, :locale => 'es'
      assert_response :success
    end
    
    last_clickthrough = Clickthrough.order("id DESC").first
    assert_equal source.class.base_class.name, last_clickthrough.click_source_type
    assert_equal source.id, last_clickthrough.click_source_id
    
    assert_equal target.class.base_class.name, last_clickthrough.click_target_type
    assert_equal target.id, last_clickthrough.click_target_id
    
    assert_equal last_clickthrough, source.clicks_from.last
    assert_equal last_clickthrough, target.clicks_to.last
  end
end  
