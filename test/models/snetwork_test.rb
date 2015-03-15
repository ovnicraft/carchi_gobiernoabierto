require 'test_helper'

class SnetworkTest < ActiveSupport::TestCase
  
  test "validates presence of url and format" do
    snet=Snetwork.new
    assert_equal false, snet.save
    assert_equal false, snet.errors[:url].empty?
    snet.url='twitter.com/irekia'
    assert_equal false, snet.save
    snet.url='http://twitter.com/irekia2'
    assert_equal true, snet.save
  end
  
  test "set label when create" do
    snet=Snetwork.new(:url => 'http://twitter.com/irekia2')
    assert_equal true, snet.save    
    assert_equal 'twitter', snet.label
    
    snet=Snetwork.new(:url => 'http://www.facebook.com/irekia2')
    assert_equal true, snet.save    
    assert_equal 'facebook', snet.label
  end
  
  test "belongs to social organizations" do
    snet=snetworks(:irekia_twitter)
    sorg=sorganizations(:social_org)
    assert_equal sorg.id, snet.sorganization_id
  end
  
  
end  