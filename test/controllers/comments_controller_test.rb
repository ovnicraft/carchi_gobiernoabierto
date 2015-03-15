require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  
  test "should get comments RSS feed" do
    get :index, :format => "rss"
    assert_response :success
    assert_not_nil assigns(:comments)
    
    expected_comments = %w(aprobado_castellano aprobado_euskera aprobado_de_interior comentario_aprobado_en_video comentario_aprobado_en_pagina aprobado_euskadi_net_es aprobado_euskadi_net_eu)
    
    expected_comments.each do |c|
      assert assigns(:comments).include?(comments(c.to_sym))
    end
    
    %w(rechazado_castellano pendiente_castellano spam_castellano rechazado_euskera pendiente_euskera spam_euskera).each do |c|
      assert !assigns(:comments).include?(comments(c.to_sym))
    end
    
    expected_comments.each do |c|
      parent = comments(c.to_sym).commentable
      parent_url = parent.is_a?(ExternalComments::Item) ? parent.url : eval("#{parent.class.to_s.downcase}_url(id:parent.id)")
      assert_select 'item>link', /#{parent_url}/
    end
  end


  test "should get news comments RSS feed" do
    news = documents(:commentable_news)
    get :index, :news_id => news.id, :format => "rss"
    assert_response :success
    assert_not_nil assigns(:comments)
    
    expected_comments = %w(aprobado_castellano aprobado_euskera official_comment aprobado_euskadi_net_es aprobado_euskadi_net_eu)
    expected_comments.each do |c|
      assert assigns(:comments).include?(comments(c.to_sym))
    end
    
    %w(rechazado_castellano pendiente_castellano spam_castellano rechazado_euskera pendiente_euskera spam_euskera aprobado_emakunde).each do |c|
      assert !assigns(:comments).include?(comments(c.to_sym))
    end
    
    expected_comments.each do |c|
      parent = comments(c.to_sym).commentable
      parent_url = parent.is_a?(ExternalComments::Item) ? parent.url : eval("#{parent.class.to_s.downcase}_url(id:parent.id)")
      assert_select 'item>link', /#{parent_url}/
    end
  end

  test "should get department comments RSS feed with news and external items" do
    news = documents(:commentable_news)
    department = news.department
    get :department, :id => department.id, :format => "rss"
    assert_response :success
    assert_not_nil assigns(:comments)
    
    expected_comments = %w(aprobado_castellano aprobado_euskera official_comment aprobado_euskadi_net_es aprobado_euskadi_net_eu aprobado_emakunde)
    expected_comments.each do |c|
      assert assigns(:comments).include?(comments(c.to_sym)), "No está el comentario #{c}"
    end
    
    %w(rechazado_castellano pendiente_castellano spam_castellano rechazado_euskera pendiente_euskera spam_euskera).each do |c|
      assert !assigns(:comments).include?(comments(c.to_sym)), "No debería estar el comentario #{c}"
    end
    
    expected_comments.each do |c|
      parent = comments(c.to_sym).commentable
      parent_url = parent.is_a?(ExternalComments::Item) ? parent.url : eval("#{parent.class.to_s.downcase}_url(id:parent.id)")
      assert_select 'item>link', /#{parent_url}/
    end
  end

  test "should get department comments RSS feed with news" do
    department = organizations(:interior)
    get :department, :id => department.id, :format => "rss"
    assert_response :success
    assert_not_nil assigns(:comments)

    assigns(:comments).each do |comment|
      assert comment.commentable.is_a?(Document)
      assert comment.commentable.department.eql?(department)
    end    
  end


  context "list comments in json" do
    should "get list for news" do
      news = documents(:commentable_news)
      get :list, :news_id => news.id, :format => :json
      assert_response :success
      assert_not_nil assigns(:comments)

      assert assigns(:comments).detect {|comment| comment.commentable.is_a?(Document)}
      assert assigns(:comments).detect {|comment| comment.commentable.is_a?(ExternalComments::Item)}    
    
      assigns(:comments).each do |comment|
        if comment.commentable.is_a?(Document)
          assert comment.commentable.eql?(news)
        end
        if comment.commentable.is_a?(ExternalComments::Item)
          assert_equal news.id, comment.commentable.irekia_news_id
        end
      end    
    end
    
    should "get list for event" do
      event = documents(:passed_event)
      get :list, :event_id => event.id, :format => :json
      assert_response :success
      assert_not_nil assigns(:comments)

      assert assigns(:comments).detect {|comment| comment.commentable.is_a?(Document)}
      assert_nil assigns(:comments).detect {|comment| comment.commentable.is_a?(ExternalComments::Item)}    
    
      assigns(:comments).each do |comment|
        if comment.commentable.is_a?(Document)
          assert comment.commentable.eql?(event)
        end
      end          
    end

   if Settings.optional_modules.proposals
    should "get list for proposal" do
      proposal = proposals(:approved_and_published_proposal)
      get :list, :proposal_id => proposal.id, :format => :json
      assert_response :success
      assert_not_nil assigns(:comments)

      assert assigns(:comments).detect {|comment| comment.commentable.is_a?(Proposal)}
      assert_nil assigns(:comments).detect {|comment| comment.commentable.is_a?(ExternalComments::Item)}    
    
      assigns(:comments).each do |comment|
        if comment.commentable.is_a?(Proposal)
          assert comment.commentable.eql?(proposal)
        end
      end
    end
   end

    should "get list for video" do
      video = videos(:every_language)
      get :list, :video_id => video.id, :format => :json
      assert_response :success
      assert_not_nil assigns(:comments)

      assert assigns(:comments).detect {|comment| comment.commentable.is_a?(Video)}
      assert_nil assigns(:comments).detect {|comment| comment.commentable.is_a?(ExternalComments::Item)}    
    
      assigns(:comments).each do |comment|
        if comment.commentable.is_a?(Video)
          assert comment.commentable.eql?(video)
        end
      end          
    end

   if Settings.optional_modules.debates
    should "get list for debate" do
      debate = debates(:debate_completo)
      get :list, :debate_id => debate.id, :format => :json
      assert_response :success
      assert_not_nil assigns(:comments)

      assert assigns(:comments).detect {|comment| comment.commentable.is_a?(Debate)}
      assert_nil assigns(:comments).detect {|comment| comment.commentable.is_a?(ExternalComments::Item)}    
    
      assigns(:comments).each do |comment|
        if comment.commentable.is_a?(Debate)
          assert comment.commentable.eql?(debate)
        end
      end          
    end
   end

    should "get list for external page" do
      external_item = external_comments_items(:euskadinet_item_commentable_irekia_news)
      get :list, "externalcomments::item_id" => external_item.id, :format => :json
      assert_response :success
      assert_not_nil assigns(:comments)

      # Salen los comentarios de la página externa y de la noticia de irekia que le corresponde.
      assert assigns(:comments).detect {|comment| comment.commentable.is_a?(Document)}
      assert assigns(:comments).detect {|comment| comment.commentable.is_a?(ExternalComments::Item)}    
      assert assigns(:comments).detect {|comment| comment.commentable.eql?(external_item)}    
    
      assigns(:comments).each do |comment|
        if comment.commentable.is_a?(Document)
          assert comment.commentable.eql?(external_item.irekia_news)
        end        
        if comment.commentable.is_a?(ExternalComments::Item)
          assert_equal external_item.irekia_news_id, comment.commentable.irekia_news_id
        end
      end          
    end
    
  end
  
  # there is no html template for comments
  # test "should get index" do
  #   get :index
  #   assert_response :success
  #   assert_not_nil assigns(:comments)
  # end

  test "should create comment" do
    login_as(:admin)
    assert_difference('Comment.count') do
      post :create, :news_id => documents(:one_news).id, :comment => {:body => "comment" }
    end
  
    assert_redirected_to news_path(assigns(:parent))
  end
  
  test "should destroy comment" do
    login_as(:admin)
    assert_difference('Comment.count', -1) do
      delete :destroy, :news_id => documents(:commentable_news).id, :id => comments(:aprobado_castellano).id
    end

    assert_redirected_to comments_path
  end
  
  def assert_comments_not_authorized
    assert_equal I18n.t('session.tienes_que_registrarte2', :what => Comment.human_name.pluralize), flash[:notice]
    assert_template ""
  end
  
  %w(superadmin admin periodista visitante colaborador jefe_de_prensa jefe_de_gabinete secretaria comentador_oficial twitter_user facebook_user).each do |role|
    test "#{role} should be able to create comments" do
      login_as(role)
      assert_difference 'Comment.count', +1 do
        post :create, :news_id => documents(:commentable_news).id, :comment => {:body => "comentario"}
      end
      assert_redirected_to documents(:commentable_news)
      assert_equal (users(role).is_official_commenter? ? I18n.t('comments.comentario_guardado') : I18n.t('comments.comment_pending')), flash[:notice]
    end
  end
  
  
  roles = %w(miembro_que_crea_noticias room_manager)
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "#{role} should not be able to create comments" do
      login_as(role)
      assert_no_difference 'Comment.count' do
        post :create, :news_id => documents(:commentable_news).id, :comment => {:body => "comentario"}
      end
      assert_redirected_to new_session_path
      assert_not_authorized
    end
  end
  
  test "comentador_oficial can change the name he signs with" do
    login_as(:comentador_oficial)
    assert_difference 'Comment.count', +1 do
      post :create, :news_id => documents(:commentable_news).id, :comment => {:body => "comentario", :name => "nombre cambiado"}
    end
    assert_equal "nombre cambiado", assigns(:comment).name
  end
  
  context "external url comments" do
    context "logged in user" do
      setup do
        login_as(:visitante)
      end

      should "create comment on external URL" do
        assert_difference 'Comment.count', 1 do
         post :create, "externalcomments::item_id" => external_comments_items(:euskadinet_item1).id, :comment => {:body => "comentario", :name => "nombre"}
        end 
      
        assert_response :redirect
      end
    end
    
    context "not logged in" do
      should "not create comment" do
        assert_no_difference 'Comment.count' do
         post :create, "externalcomments::item_id" => external_comments_items(:euskadinet_item1).id, :comment => {:body => "comentario", :name => "nombre"}
        end 
      
        assert_response :redirect
      end
    end
  end

end
