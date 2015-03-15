require 'test_helper'

class ArgumentTest < ActiveSupport::TestCase

 if Settings.optional_modules.proposals
  context "notifications" do
    should "not create notification for unapproved argument in unapproved proposal" do
      assert_no_difference 'Notification.count' do
        comment = proposals(:unapproved_proposal).arguments.create(:user => users(:visitante), :value => 1, :reason => "yes we can")
      end
    end

    should "not create notification for approved argument in unapproved proposal" do
      assert_no_difference 'Notification.count' do
        comment = proposals(:unapproved_proposal).arguments.create(:user => users(:visitante), :value => 1, :reason => "yes we can", :published_at => 3.hours.ago)
      end
    end

    should "not create notification for unapproved argument in approved proposal" do
      assert_no_difference 'Notification.count' do
        comment = proposals(:approved_and_published_proposal).arguments.create(:user => users(:visitante), :value => 1, :reason => "yes we can")
      end
    end

    should "create notification for approved argument in approved proposalxx" do
      assert_difference 'Notification.count', +1 do
        comment = proposals(:approved_and_published_proposal).arguments.create(:user => users(:visitante), :value => 1, :reason => "yes we can", :published_at => 3.hours.ago)
      end
    end
  end

  context "stats_counters" do
    should "proposal without stats entry create and populate stats" do
      proposal = proposals(:approved_and_published_proposal)
      argument = FactoryGirl.create(:in_favor_proposal_argument, :argumentable => proposal) # not published
      assert_argument_counters(argument.argumentable)
      argument = FactoryGirl.create(:published_in_favor_proposal_argument, :argumentable => proposal)
      assert_argument_counters(argument.argumentable)
    end

    context "in new proposal" do
      setup do
        @proposal_argument = FactoryGirl.create(:in_favor_proposal_argument)
      end

      should "update counters when creating a new argument" do
        assert_argument_counters(@proposal_argument.argumentable)
      end

      should "update counters when deleting a arguent" do
        @proposal_argument.destroy
        assert_argument_counters(@proposal_argument.argumentable)
      end

      should "update counters when approving an argument" do
        @proposal_argument.approve!
        assert_argument_counters(@proposal_argument.argumentable)
      end
    end

  end
 end
end
