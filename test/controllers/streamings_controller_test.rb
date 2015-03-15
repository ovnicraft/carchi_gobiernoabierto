require 'test_helper'

class StreamingsControllerTest < ActionController::TestCase
 if Settings.optional_modules.streaming
  test "should show index for irekia" do
    sf = stream_flows(:sf_two)
    sf.announced_in_irekia = true
    assert sf.save
    
    get :index, :locale => 'es'
    assert assigns(:flows).detect {|f| f.eql?(sf)}
    assert_template layout: 'layouts/application'
  end

  test "should show streaming page for streaming for irekia without event in irekia" do
    sf = stream_flows(:sf_one)
    assert sf.update_attribute(:event_id, nil)
    assert_nil sf.event
    sf.announced_in_irekia = true
    assert sf.save
    
    get :show, :id => sf.id
    assert_response :success
    assert_template layout: 'layouts/application'
  end
  
  test "should redirect to event page for streaming with irekia event in irekia" do
    sf = stream_flows(:sf_one)
    event = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    assert sf.update_attribute(:event_id, event.id)
    
    assert_not_nil sf.event
    assert sf.event.is_public?
    
    get :show, :id => sf.id
    assert_response :redirect
    assert_redirected_to event_url(sf.event)
  end
  
  test "should redirect to not found for streaming with agencia event in irekia unless stream_flow is show_in_irekia" do
    sf = stream_flows(:sf_one)
    event = documents(:private_event)
    event.update_attribute(:irekia_coverage, true)
    assert sf.update_attributes(:event_id => event.id, :show_in_irekia => false)
    
    assert_not_nil sf.event
    assert sf.event.is_private?
    
    get :show, :id => sf.id, :format => :html
    assert_response :missing
    assert_template 'site/notfound.html', layout: 'layouts/application'
  end
  
  test "should show streaming with agencia event in irekia if stream_flow is show_in_irekiaxx" do
    sf = stream_flows(:sf_one)
    event = documents(:private_event)
    event.update_attribute(:irekia_coverage, true)
    assert sf.update_attributes(:event_id => event.id, :show_in_irekia => true)
    
    assert_not_nil sf.event
    assert sf.show_in_irekia?
    assert !sf.event.is_public?
    
    get :show, :id => sf.id
    assert_response :success
    assert_template layout: 'layouts/application'
  end
 end
  
end
