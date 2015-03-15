require 'test_helper'

class VoteTest < ActiveSupport::TestCase
 if Settings.optional_modules.proposals
  test "should get citizen proposals votes" do
    assert Vote.for_prop_from_citizens.count > 0
  end

  test "should get gov proposals votes" do
    assert Vote.for_prop_from_politicians
  end

  context "notifications" do
    should "not create notification for vote in unapproved proposal" do
      assert_no_difference 'Notification.count' do
        comment = proposals(:unapproved_proposal).votes.create(:user => users(:visitante), :value => 1)
      end
    end

    should "create notification for vote in approved proposalxx" do
      assert_difference 'Notification.count', +1 do
        comment = proposals(:approved_and_published_proposal).votes.create(:user => users(:visitante), :value => 1)
      end
    end
  end

  context "stats_counters" do
    should "proposal without stats entry create and populate stats" do
      proposal = proposals(:approved_and_published_proposal)
      vote = FactoryGirl.create(:positive_proposal_vote, :votable => proposal) # not published
      assert_vote_counters(vote.votable)
    end

    context "in new proposal" do
      setup do
        @proposal_vote = FactoryGirl.create(:positive_proposal_vote)
      end

      should "update counters when creating a new vote" do
        assert_vote_counters(@proposal_vote.votable)
      end

      should "update counters when deleting a vote" do
        @proposal_vote.destroy
        assert_vote_counters(@proposal_vote.votable)
      end

      should "update counters when approving an vote" do
        @proposal_vote.update_attributes(:value => -1) # rare
        assert_vote_counters(@proposal_vote.votable)
      end
    end
  end
 end
end
