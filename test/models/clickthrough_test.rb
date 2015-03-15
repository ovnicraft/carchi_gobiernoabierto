require 'test_helper'

class ClickthroughTest < ActiveSupport::TestCase

  should "be valid with all info" do
    assert Clickthrough.new(default_values).valid?
  end
  
  should "be valid without a target" do
    assert Clickthrough.new(default_values.merge(:click_target_type => nil, :click_target_id => nil)).valid?
  end
  
  should "be invalid without click_target_type" do
    assert !Clickthrough.new(default_values.merge(:click_target_type => nil)).valid?
  end
  
  should "be valid without click_target_id" do
    # Note: target will be ignored and the bulletin image will be returned
    assert Clickthrough.new(default_values.merge(:click_target_id => nil)).valid?
  end
  
  should "be invalid without click_source_id" do
    assert !Clickthrough.new(default_values.merge(:click_source_id => nil)).valid?
  end
  
  should "be invalid without click_source_type" do
    assert !Clickthrough.new(default_values.merge(:click_source_type => nil)).valid?
  end
  
  should "be valid without a source" do
    assert !Clickthrough.new(default_values.merge(:click_source_type => nil, :click_source_id => nil)).valid?
  end
  
  def default_values
    {:click_source_type => "BulletinCopy", :click_source_id => bulletin_copies(:for_visitante).id,
      :click_target_type => 'Document', :click_target_id => documents(:one_news).id, :locale => 'es',
      :user_id => users(:visitante).id}
  end
  
end
