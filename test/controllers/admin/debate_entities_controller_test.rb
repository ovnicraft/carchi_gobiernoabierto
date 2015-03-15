require 'test_helper'

class Admin::DebateEntitiesControllerTest < ActionController::TestCase
 if Settings.optional_modules.debates
  def setup 
    login_as('admin')
    ActionMailer::Base.deliveries = []
  end
  
  context "with debate" do
    setup do
       @debate = debates(:debate_completo)
    end
    
    should "create debate entity" do
      entidad_nueva = outside_organizations(:organization_without_debate)
      assert_difference "DebateEntity.count", 1 do
        post :create, :debate_id => @debate.id, :debate_entity => {"url_es"=>"http://google.es", "organization_name"=>entidad_nueva.name}
      end
      assert_response :redirect
    end
  end
 end
end
