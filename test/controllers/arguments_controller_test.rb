require 'test_helper'

class ArgumentsControllerTest < ActionController::TestCase
 if Settings.optional_modules.proposals
  context "lehendakaritza area" do 
    setup do
      @proposal = proposals(:approved_and_published_proposal)
    end
    
    should "require login to create argument" do
      post :create, :proposal_id => @proposal.id
      assert_redirected_to new_session_path
    end
    
    context "logged in as visitante" do
      setup do 
        login_as("visitante")
      end
      
      should "create argument" do
        assert_difference 'Argument.count' do
          xhr :post, :create, :proposal_id => @proposal.id, :argument => {:value => "1", :reason => "I like it"}
        end
      end
      
      context "floki" do
        should "create argument" do
          assert_difference 'Argument.count' do
            post :create, :format => "floki", :proposal_id => @proposal.id, "data"=>"{\"argument_choice\":2,\"controller_id\":130000,\"item_id\":#{@proposal.id},\"argument_text\":\"Mi argumento\"}"
          end          
        end        
      end
      
    end
  end
 end
end
