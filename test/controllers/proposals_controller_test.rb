require 'test_helper'

class ProposalsControllerTest < ActionController::TestCase
 if Settings.optional_modules.proposals 
  context "lehendakaritza area" do 
    setup do
      @lehen = areas(:a_lehendakaritza)
    end
    
    should "login is required to make a proposal" do
      get :new, :area_id => areas(:a_lehendakaritza).to_param
      assert_redirected_to new_session_path
    end
  
    should "unlogged user cannot create proposal" do
      post :create, :proposal => {:title_es => "Titulo", :body_es => "body", :area_tags => [@lehen.area_tag.name_es]}
      assert_redirected_to new_session_path
    end
  
    %w(twitter_user visitante facebook_user).each do |role|
      should "#{role} can create proposal" do
        login_as("visitante")
        get :new, :area_id => areas(:a_lehendakaritza).id
        assert_response :success
        assert_template "new"
        assert_select "form" do
          assert_select "[action=?]", proposals_path
        end
    
        assert_difference 'Proposal.count', +1 do
          post :create, :proposal => {:title_es => "Titulo", :body_es => "body", :area_tags => [@lehen.area_tag.name_es]}
        end
      end
      
    end  
  
    should "should list untranslated proposals" do
      get :index, :area_id => areas(:a_lehendakaritza).to_param
      assert assigns(:proposals).include?(proposals(:approved_and_published_proposal_in_basque))
    end
    
    
    should "not list other area proposals" do
      get :index, :area_id => areas(:a_lehendakaritza).to_param
      assert !assigns(:proposals).include?(proposals(:interior_proposal))
      assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', proposal_path(assigns(:proposals).first)
    end

    context "rss" do
      should "show proposals index" do
        get :index, :format => 'rss'
        assert_response :success
        
        assert_equal I18n.t('proposals.feed_title', :name => Settings.site_name), assigns(:feed_title)
        assert_template 'proposals/index'
      end

      should "show only proposals from this area index" do
        get :index, :area_id => areas(:a_lehendakaritza).id, :format => 'rss'
        assert_response :success
        
        assert_equal "Peticiones ciudadanas de Lehendakaritza", assigns(:feed_title)
        assert_template 'proposals/index'
        assert assigns(:proposals).collect(&:area).uniq == [areas(:a_lehendakaritza)]
      end
    end
    
    # should "return area proposals when using the departments filter" do
    #   lehendakaritza = areas(:a_lehendakaritza)
    #   xhr :get, :index, :area_id => lehendakaritza.id
    #   assert assigns(:proposals)
    #   assert assigns(:proposals).collect(&:area_id).uniq == [lehendakaritza.id]
    #   assert_equal 'text/html', @response.content_type
    #   assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', proposal_path(assigns(:proposals).first)
    # end
    
    should "show area filter in news index" do
      get :index
      assert_select 'div.filters ul li' do
        assert_select 'form[action=?]', '/es/proposals'
        assert_select 'select[name=?]', "area_id"
      end
    end

    should "show politician filter in area news" do
      lehendakaritza = areas(:a_lehendakaritza)
      get :index, :area_id => lehendakaritza.id
      assert_select 'div.filters', :count => 0
    end
    
    %w(unpublished_proposal unsearchable_proposal unapproved_proposal draft_proposal).each do |prop|
      should "not list #{prop}" do
        get :index, :area_id => @lehen.id
        assert !assigns(:proposals).include?(proposals(prop))
      end
    end
    
    should "show proposals from inactive department" do
      get :index
      assert assigns(:proposals).include?(proposals(:proposal_from_inactive_department))
    end

    should "show question from inactive department in area page" do
      get :index, :area_id => areas(:a_interior).to_param
      assert assigns(:proposals).include?(proposals(:proposal_from_inactive_department))
    end
    
    
    %w(unpublished_proposal unsearchable_proposal unapproved_proposal draft_proposal).each do |prop|
      should "not show #{prop}" do
        get :show, :id => proposals(prop).to_param, :area_id => @lehen.id
        assert_template 'site/notfound.html'
      end
    end
  
    should "should show untranslated proposals" do
      get :show, :id => proposals(:approved_and_published_proposal_in_basque).to_param, :area_id => @lehen.id
      assert_response :success
      assert :template => "show"
    end
    
    should "show department feed" do
      get :department, :id => organizations(:lehendakaritza).id, :format => :rss
      assert_response :success
    end

    context "logged in as visitante" do
      setup do 
        login_as("visitante")
      end

      should "show 'crea una propuesta' link" do
        get :index, :area_id => @lehen.id
                
        assert_select 'a#proposal-popover'
      end
      
      should "list unapproved proposal to owner" do
        get :index, :area_id => @lehen.id
        assert !assigns(:proposals).include?(proposals(:unapproved_proposal))
      end
      
      should "show unapproved proposal to owner" do
        get :show, :id => proposals(:unapproved_proposal).to_param, :area_id => @lehen.id
        assert_response :success
      end
      
      context "create via ajax" do
        setup do
          ActionMailer::Base.deliveries = []
          
          assert_difference 'Proposal.count', +1 do
            xhr :post, :create, :proposal => {:title_es => "Titulo", :body_es => "body", :area_tags => [@lehen.area_tag.name_es]}
          end
        end
        should "work" do
          assert_response :success        
          assert_select 'h2', I18n.t('proposals.create.title')
          assert !assigns(:proposal).approved?
        end
        
        should "assign correct area tag" do
          assigns(:proposal).reload
          assert_equal @lehen, assigns(:proposal).area
        end
        
        should 'send email to administrators' do
          assert_equal 1, ActionMailer::Base.deliveries.size
          email = ActionMailer::Base.deliveries.last
          assert_equal Proposal::MODERATORS.sort, email.to.sort
          assert email.subject.match("Nueva propuesta en #{Settings.site_name}")
        end
      end
      
      
      context "show proposal" do
        setup do
          @proposal =proposals(:approved_and_published_proposal)
          get :show, :id => @proposal.to_param, :area_id => @lehen.id
        end
        
        should "show vote links" do
          assert_select 'input.in_favor[type=submit]'
          assert_select 'input.against[type=submit]'
        end
        
        should "show argument forms" do
          assert_select "form[action=?]", proposal_arguments_path(@proposal)
        end
        
        should "show comments" do
          assert_select 'div.comments' do
            assert_select 'div.count', I18n.t('comments.title_with_count', :count => 1)
          end
        end
        
        should "show not answered text" do
          assert_select 'div.answer_info' do
            assert_select 'span.not_answered', I18n.t('proposals.not_answered')
          end
        end
      end

      context "with official_comment" do
        setup do
          @proposal = proposals(:approved_and_published_proposal)
          @proposal.comments.create!(:user => users(:admin), :body => 'comentario oficial')
        end
        should "show answered text" do
          get :show, :id => @proposal.to_param
          assert_select 'div.answer_info' do
            assert_select 'a.answered', /Contestada tras/
          end
        end
      end
      
      context "voted proposal" do
        setup do
          @proposal = proposals(:approved_and_published_proposal_in_basque)
          get :show, :id => @proposal.to_param, :area_id => @lehen.id
        end
        
        should "not disable vote links for voted proposal" do
          assert_select 'input.in_favor[disabled=disabled]'
          assert_select 'input.against[disabled=disabled]'
        end
      end
    end
    
    context "logged in as politician" do
      setup do 
        login_as(:politician_one)
      end
      
      should "show 'crea una propuesta' link" do
        get :index, :area_id => @lehen.id
                
        assert_select 'a#proposal-popover'
      end
    end
    
    should "return area proposals when using the departments filter" do
      xhr :get, :index, :area_id => @lehen.id
      assert assigns(:proposals)
      assert assigns(:proposals).collect(&:area).uniq == [@lehen]
      assert_equal 'text/html', @response.content_type
      assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', proposal_path(assigns(:proposals).first)
    end
    
  end
  
  #context "sin area ni politico" do
  #  should "list proposal of all areas" do
  #    get :index
  #    assert assigns(:proposals).include?(proposals(:interior_proposal))
  #    assert assigns(:proposals).include?(proposals(:approved_and_published_proposal))
  #    assert assigns(:proposals).include?(proposals(:governmental_proposal))
  #  end    
  #  
  #  should "return all proposals when using the departments filter reset link" do
  #    xhr :get, :index
  #    assert assigns(:proposals)
  #    assert assigns(:proposals).collect(&:area).uniq.length == 0
  #    assert_equal 'text/html', @response.content_type
  #    assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', proposal_path(assigns(:proposals).first)
  #  end
  #end


  test "should track clickthrough when clicking on a search result" do
    assert_content_is_tracked(criterios(:criterio_one), proposals(:interior_proposal))
  end
  
  test "should track clickthrough when clicking on a tag item" do
    assert_content_is_tracked(tags(:viajes_oficiales), proposals(:interior_proposal))
  end  
 end
end
