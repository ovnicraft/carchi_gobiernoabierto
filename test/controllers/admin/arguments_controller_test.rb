require 'test_helper'

class Admin::ArgumentsControllerTest < ActionController::TestCase
  def setup 
    login_as('admin')
    ActionMailer::Base.deliveries = []
  end
  
 if Settings.optional_modules.proposals
  context "with proposal arguments" do
    setup do
      proposals(:approved_and_published_proposal).arguments.create(:value => 1, :reason => 'Un argumento a favor', :user_id => users(:visitante).id)
    end
    
    should "get arguments list" do
      get :index
      assert_response :success
    end
   end
  end
end
