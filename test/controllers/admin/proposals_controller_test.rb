require 'test_helper'

class Admin::ProposalsControllerTest < ActionController::TestCase
 if Settings.optional_modules.proposals
  def setup
    login_as('admin')
    ActionMailer::Base.deliveries = []
  end

  test "only citizen proposals are shown" do
    get :index

    assert_select "div.submenu" do
      assert_select 'li', :text => "Peticiones"
      assert_select 'li', :text => "Argumentos"
      assert_select 'li', :text => "Gubernamentales", :count => 0
    end
  end

  test "show proposals arguments" do
    get :arguments

    assert_response :success
    assert assigns(:arguments)
    assert_nil assigns(:arguments).detect {|a| a.argumentable_type.eql?('Debate')}
  end

  test "pending proposal without organization cannot be approved" do
    proposal = proposals(:unapproved_proposal)
    get :index
    assert_select "tr#proposal_#{proposal.id} td.status" do
      assert_select 'a', :count => 1
      assert_select 'a', 'Eliminar' #no hay link de aprobar
    end
  end

  context "with lehendakaritza proposal" do
    setup do
      @proposal = proposals(:unapproved_proposal)
      @proposal.update_attribute(:organization_id, organizations(:lehendakaritza).id)
      @proposal.reload
    end

    should "show proposal" do
      get :show, :id => @proposal.id
      assert_response :success
    end

    should "pending proposal with organization can be approved" do
      get :index
      assert_select "tr#proposal_#{@proposal.id} td.status" do
        assert_select 'a', 'Aprobar'
      end
    end

    should "send email to author and department staff when approving proposal" do
      xhr :put, :update, :id => @proposal.id, :proposal => {:status => 'aprobado'}
      # son 2, uno al departament_editor y al department member con permiso para responder oficialmente y otro al autor
      assert_equal 2, ActionMailer::Base.deliveries.size
      email = ActionMailer::Base.deliveries.detect {|e| e.to.eql?([@proposal.user.email])}
      # email = ActionMailer::Base.deliveries.last
      # assert_equal [@proposal.user.email], email.to
      assert email.subject.match(I18n.t('notifier.proposal_approval.subject', :site_name => Settings.site_name))
    end

    should "changing pending proposal's department does not send email to department responders" do
      put :update, :id => @proposal.id, :proposal => {:organization_id => organizations(:emakunde).id}
      assert_equal 0, ActionMailer::Base.deliveries.size
    end

    context "approve proposal" do
      setup do
        @proposal = proposals(:featured_proposal)
      end

      should "changing department sends email to department responders" do
        put :update, :id => @proposal.id, :proposal => {:organization_id => organizations(:interior).id}
        # uno para el department editor y dos para los department members official commenters del departamento nuevo
        assert_equal 1, ActionMailer::Base.deliveries.size
        email = ActionMailer::Base.deliveries.last
        @proposal.reload
        assert_equal (@proposal.department.department_editors.collect(&:email)+@proposal.department.department_members_official_commenters.collect(&:email)).sort, email.to.sort
        assert email.subject.match("Nueva propuesta en #{Settings.site_name}")
      end
    end
  end

  context "jefe de prensa" do
    setup do
      @department_editor = users(:jefe_de_prensa)
      login_as(:jefe_de_prensa)
      get :index
    end

    should respond_with(:success)

    should render_template(:index)

    should "list only her department's proposals" do
      assert_equal [@department_editor.department_id], assigns(:proposals).collect(&:organization_id).uniq
    end

    should "allow department editor to moderate her department's proposals" do
      assert_select 'table.comments tr td.status' do
        assert_select 'div.status_links'
      end
    end
  end

  context "miembro de departamento" do
    setup do
      @department_member = users(:secretaria_interior)
      login_as(:secretaria_interior)
      get :index
    end

    should respond_with(:redirect)

    should "assert_not_authorized" do
      assert_not_authorized
    end

    context "with proposal moderation permission" do
      setup do
        @department_member.permissions.create(:module => "proposals", :action => "edit")
        get :index
      end

      should respond_with(:success)

      should render_template(:index)

      should "list only her department's proposals" do
        assert_equal [@department_member.department_id], assigns(:proposals).collect(&:organization_id).uniq
      end

      should "allow department editor to moderate her department's proposals" do
        assert_select 'table.comments tr td.status div.status_links' do
          assert_select 'a'
        end
      end
    end

    context "with official comment permission" do
      setup do
        @department_member.permissions.create(:module => "comments", :action => "official")
        get :index
      end

      should respond_with(:success)

      should render_template(:index)

      should "list only her department's proposals" do
        assert_equal [@department_member.department_id], assigns(:proposals).collect(&:organization_id).uniq
      end

      should "not allow department editor to moderate her department's proposals" do
        assert_select 'table.comments tr td.status div.status_links ' do
          assert_select 'a', :count => 0
        end
      end

      should "not be able to edit proposals" do
        get :edit, :id => proposals(:draft_proposal)
        assert_not_authorized
      end
    end

  end
 end
end
