require 'test_helper'

class DebateEntityTest < ActiveSupport::TestCase
 if Settings.optional_modules.debates 
  context "with debate" do
    setup do
       @debate = debates(:debate_completo)
    end
    
    should "assign organization when exists" do
      organization = outside_organizations(:organization_without_debate)
      de = DebateEntity.new(:debate => @debate, :organization_name => organization.name_es)
      assert_no_difference "OutsideOrganization.count" do  
        assert de.save
      end
      assert_equal organization, de.organization
    end
    
    should "create and assign organization when does not exist" do
      organization = outside_organizations(:organization_without_debate)
      de = DebateEntity.new(:debate => @debate, :organization_name => organization.name_es+" (nueva)")
      assert_difference "OutsideOrganization.count", 1 do
        assert de.save
      end
      assert_not_equal organization, de.organization
    end
  end
 end
end
