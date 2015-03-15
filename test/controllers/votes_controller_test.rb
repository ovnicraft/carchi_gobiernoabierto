require 'test_helper'

class VotesControllerTest < ActionController::TestCase
 if Settings.optional_modules.proposals
  context "lehendakaritza area" do 
    setup do
      @proposal = proposals(:approved_and_published_proposal)
    end
    
    context "unlogged user" do      
      should "require login to vote" do
        post :create, :proposal_id => @proposal.id
        assert_redirected_to new_session_path
      end
      context "floki" do
        should "not create vote" do
          assert_no_difference 'Vote.count' do
            post :create, :format => "floki", :proposal_id => @proposal.id, "data"=>"{\"vote_choice\":2,\"controller_id\":130000,\"item_id\":#{@proposal.id}}"
          end          
        end
      end
      
    end
    
    context "logged in as visitante" do
      setup do 
        login_as("visitante")
      end
      
      should "vote" do
        assert_difference 'Vote.count' do
          post :create, :proposal_id => @proposal.id, :vote => {:value => "1"}
        end
      end
      
      context "floki" do
        should "create vote" do
          assert_difference 'Vote.count' do
            post :create, :format => "floki", :proposal_id => @proposal.id, "data"=>"{\"vote_choice\":2,\"controller_id\":130000,\"item_id\":#{@proposal.id}}"
          end          
        end
        
        should "not allow same user to vote twice" do
          Vote.create(:user_id => users(:visitante).id, :votable_type => 'Proposal', :votable_id => @proposal.id, :value => 1)
          assert_no_difference 'Vote.count' do
            post :create, :format => "floki", :proposal_id => @proposal.id, "data"=>"{\"vote_choice\":2,\"controller_id\":130000,\"item_id\":#{@proposal.id}}"
          end
        end
      end
    end
  end
 end
end
