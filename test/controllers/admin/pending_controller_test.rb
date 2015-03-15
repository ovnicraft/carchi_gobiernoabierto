require 'test_helper'

class Admin::PendingControllerTest < ActionController::TestCase

  test "should get index" do
    login_as('admin')
    get :index
    assert_response :success
    assert_template "index"
  end

  test "should approve comment" do
    login_as('admin')
    comment = comments(:pendiente_castellano)
    put :approve, :pending_id => comment.id, :pending_type => 'Comment'
    comment.reload
    assert_response :redirect
    assert_redirected_to admin_pending_path
    assert_equal 'aprobado', comment.status
  end

  test "should spam comment" do
    login_as('admin')
    comment = comments(:pendiente_castellano)
    put :spam, :pending_id => comment.id, :pending_type => 'Comment'
    comment.reload
    assert_response :redirect
    assert_redirected_to admin_pending_path
    assert_equal 'spam', comment.status
  end

  test "should reject comment" do
    login_as('admin')
    comment = comments(:pendiente_castellano)
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      put :reject, :pending_id => comment.id, :pending_type => 'Comment'
    end
    comment.reload
    assert_response :redirect
    assert_redirected_to admin_pending_path
    assert_equal 'rechazado', comment.status
  end

  test "should reject comment with email" do
    login_as('admin')
    comment = comments(:pendiente_castellano)
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      put :reject, :pending_id => comment.id, :pending_type => 'Comment', :send_reject_email => 'Rechazar con email'
    end  
    comment.reload
    assert_response :redirect
    assert_redirected_to admin_pending_path
    assert_equal 'rechazado', comment.status
  end

  test "should delete comment" do
    login_as('admin')
    comment = comments(:pendiente_castellano)
    assert_difference 'Comment.count', -1 do
      delete :destroy, :pending_id => comment.id, :pending_type => 'Comment'
    end  
    assert_response :redirect
    assert_redirected_to admin_pending_path
  end


 if Settings.optional_modules.debates
  test "should approve debate argument" do
    login_as('admin')
    argument = arguments(:pendiente_debate_argument)
    put :approve, :pending_id => argument.id, :pending_type => 'Argument'
    argument.reload
    assert_response :redirect
    assert_redirected_to admin_pending_path
    assert_equal 'aprobado', argument.status
  end

  test "should reject debate argument" do
    login_as('admin')
    argument = arguments(:pendiente_debate_argument)
    assert_difference 'Argument.count', -1 do
      put :reject, :pending_id => argument.id, :pending_type => 'Argument'
    end
    assert_response :redirect
    assert_redirected_to admin_pending_path
  end
 end

 if Settings.optional_modules.proposals
  test "should approve proposal argument" do
    login_as('admin')
    argument = arguments(:pendiente_proposal_argument)
    put :approve, :pending_id => argument.id, :pending_type => 'Argument'
    argument.reload
    assert_response :redirect
    assert_redirected_to admin_pending_path
    assert_equal 'aprobado', argument.status
  end

  test "should reject proposal argument" do
    login_as('admin')
    argument = arguments(:pendiente_proposal_argument)
    assert_difference 'Argument.count', -1 do
      put :reject, :pending_id => argument.id, :pending_type => 'Argument'
    end
    assert_response :redirect
    assert_redirected_to admin_pending_path
  end

  test "should edit proposal" do
    login_as('admin')
    proposal = proposals(:unapproved_proposal)
    get :edit_proposal, :pending_id => proposal.id, :pending_type => 'Proposal'
    assert_response :success
    assert_template 'edit_proposal'
  end

  test "should not approve proposal without organization" do
    login_as('admin')
    proposal = proposals(:unapproved_proposal)
    put :approve, :pending_id => proposal.id, :pending_type => 'Proposal', :pending => {:organization_id => ''}
    proposal.reload
    assert_equal 'pendiente', proposal.status
  end

  test "should approve proposal with organization" do
    login_as('admin')
    proposal = proposals(:unapproved_proposal)
    organization = organizations(:lehendakaritza)
    put :approve, :pending_id => proposal.id, :pending_type => 'Proposal', :pending => {:organization_id => organization.id}
    proposal.reload
    assert_equal 'aprobado', proposal.status
    assert_equal true, proposal.published?
    assert_equal organization, proposal.organization
  end

  test "should reject proposal" do
    login_as('admin')
    proposal = proposals(:draft_proposal)
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      put :reject, :pending_id => proposal.id, :pending_type => 'Proposal'
    end
    assert_response :redirect
    assert_redirected_to admin_pending_path
    proposal.reload
    assert_equal 'rechazado', proposal.status
  end

  test "should reject proposal with email" do
    login_as('admin')
    proposal = proposals(:draft_proposal)
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      put :reject, :pending_id => proposal.id, :pending_type => 'Proposal', :send_reject_email => 'Rechazar con email'
    end  
    proposal.reload
    assert_response :redirect
    assert_redirected_to admin_pending_path
    assert_equal 'rechazado', proposal.status
  end
 end
end
