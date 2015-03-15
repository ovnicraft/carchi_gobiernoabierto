require 'test_helper'

class DebateStageTest < ActiveSupport::TestCase
 if Settings.optional_modules.debates
  DebateStage::STAGES.each do |stage_label|
    should allow_value(stage_label.to_s).for(:label)
  end
  
  should_not allow_value("algo que no es stage").for(:label)
  
  should validate_presence_of(:starts_on)
  
  context "validate dates" do
    should "not be valid if ends_on precedes starts_on" do
      stage = DebateStage.new(:label => 'presentation', :starts_on => Date.today, :ends_on => Date.today - 1.day)
      assert !stage.valid?
      assert_equal ["La fecha de fin debe ser posterior o igual a la de inicio"], stage.errors[:base]
    end

    should "be valid if ends_on equals starts_on" do
      stage = DebateStage.new(:label => 'presentation', :starts_on => Date.today, :ends_on => Date.today)
      assert stage.valid?
    end    

    should "be valid if ends_on follows starts_on" do
      stage = DebateStage.new(:label => 'presentation', :starts_on => Date.today, :ends_on => Date.today+1.day)
      assert stage.valid?
    end    
  end
  
  should "set position on create" do
    stage = DebateStage.new(:starts_on => Date.today, :label => 'presentation')
    assert stage.save
    assert_equal 1, stage.position
  end
 end
end
