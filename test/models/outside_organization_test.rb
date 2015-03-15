require 'test_helper'

class OutsideOrganizationTest < ActiveSupport::TestCase
  should validate_presence_of(:name_es)
  
  context "with logo" do
    setup do
      @organization = OutsideOrganization.new(:name_es => "Entidad fuera del GV")
    end
    
    teardown do
      # @organization.remove_logo!
      FileUtils.rm_rf(Dir["#{Rails.root}/test/uploads/outside_organization"])
    end
        
    should "not upload logo with size different from 70x70" do
      @organization.logo = File.open(File.join(Rails.root, 'test/data/photos', 'test.jpg'))
      assert !@organization.save
      assert @organization.errors[:logo]
    end

    should "upload logo with size 70x70" do
      @organization.logo = File.open(File.join(Rails.root, 'test/data/photos', 'test70x70.png'))
      assert @organization.save
      assert @organization.logo?
    end
  end
  
 if Settings.optional_modules.debates
  context "with debate" do
    setup do 
      @debate = debates(:debate_completo)
      @org = outside_organizations(:organization_for_debate)
    end
    
    should "have debates" do
      assert @org.debates
      assert @org.debates.detect {|d| d.eql?(@debate)}
    end
  end
 end
end
