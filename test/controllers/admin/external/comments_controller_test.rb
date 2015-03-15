require 'test_helper'

class Admin::External::CommentsControllerTest < ActionController::TestCase
  context "as admin" do
    setup do
      login_as("admin")
    end
    
    context "list of external comments" do
      should "show all comments" do
        get :index
        assert_response :success

        assert assigns(:comments)
        assert_nil assigns(:comments).detect {|c| c.commentable_type != "ExternalComments::Item"}
        assert assigns(:comments).detect {|c| c.commentable.client.organization_id.eql?(organizations(:emakunde).id)}
        assert assigns(:comments).detect {|c| c.commentable.client.organization_id.eql?(organizations(:lehendakaritza).id)}        
      

        assert_select "div.one_news_submenu ul" do
          assert_select "li", Settings.site_name
          assert_select "li", "Páginas externas"        
          assert_select "li", "Webs clientes"
        end  
      end
      
      should "filter by department with comments" do
        dept_id = organizations(:lehendakaritza).id
        get :index, :dep_id => dept_id
        assert_response :success
      
        assert assigns(:department_tag_id)
        assert assigns(:comments)
        assert assigns(:comments).length > 0
        assert_nil assigns(:comments).detect {|c| c.commentable.client.organization.department.id != dept_id}
        assert assigns(:comments).detect {|c| c.commentable.client.organization_id.eql?(organizations(:emakunde).id)}
        assert assigns(:comments).detect {|c| c.commentable.client.organization_id.eql?(dept_id)}        
      end

      should "filter by department without comments" do
        dept_id = organizations(:educacion).id
        get :index, :dep_id => dept_id
        assert_response :success

        assert assigns(:department_tag_id)
        assert assigns(:comments)
        assert assigns(:comments).length.eql?(0)
      end
      
    end    
    
    context "for pending comment" do
      setup do
        @request.env["HTTP_REFERER"] = admin_external_comments_url()
      
        @comment = comments(:pendiente_euskadinet)
        assert @comment.pending?
      end
      
      should "approve comment" do
        # xhr :post, :update_status, :id => @comment.id, :comment => {:status => "aprobado"}
        xhr :post, :update_status, :id => @comment.id, :do_action => "approve"
        assert_response :success
      
        @comment.reload
        assert @comment.approved?
      end

      should "reject comment without email" do
        xhr :post, :do_reject, :id => @comment.id, :return_to => admin_external_comments_path()
        assert_response :redirect
        assert_redirected_to admin_external_comments_path()        
      
        @comment.reload
        assert @comment.rejected?
      end

      should "reject comment with email" do
        assert_difference 'ActionMailer::Base.deliveries.count', 1 do
          xhr :post, :do_reject, :id => @comment.id, :reject_and_mail => "Rechazar y enviar email", :return_to => admin_external_comments_path()
          assert_response :redirect
        end
        assert_redirected_to admin_external_comments_path()
      
        @comment.reload
        assert @comment.rejected?
      end


      should "mark as spam" do      
        # xhr :post, :mark_as_spam, :id => @comment.id
        xhr :post, :update_status, :id => @comment.id, :do_action => 'mark_as_spam'
        assert_response :success
      
        @comment.reload
        assert @comment.spam?
      end

      should "delete comment" do      
        assert_difference("Comment.count", -1) do
          xhr :post, :destroy, :id => @comment.id
        end      
        assert_response :success
      end
      
      should "show comments on item" do
        get :comments_on_item, :id => @comment.commentable_id
        assert_response :success
        
        assert_select "p#comments_status", :text => /Cerrar comentarios en este comentario externo/
      end
      
      should "close comments on item" do
        assert !@comment.commentable.comments_closed?
        put :update_comments_status, :item_id => @comment.commentable_id, :comments_closed =>"true"
        assert_response :redirect
        
        @comment.commentable.reload
        assert @comment.commentable.comments_closed? 
      end
      
    end    
  end
  
  context "as jefe de prensa" do
    setup do
      login_as("jefe_de_prensa")
      @department = organizations(:lehendakaritza)
      @external_item = external_comments_items(:euskadinet_item1)
    end
    
    should "see only comments for department clientes" do
      get :index
      assert_response :success
      
      assert assigns(:comments)
      assert_nil assigns(:comments).detect {|c| c.commentable_type != "ExternalComments::Item"}
      item_comments_ids = @external_item.comments.map {|c2| c2.id}
      assert assigns(:comments).detect {|c| item_comments_ids.include?(c.id)}, "Expected comments not found"
      
      assert_select "div.one_news_submenu ul" do
        assert_select "li", Settings.site_name
        assert_select "li", "Páginas externas"        
        assert_select "li", :text => "Webs clientes", :count => 0
      end
    end
    
    context "for pending comment" do
      setup do
        @request.env["HTTP_REFERER"] = admin_external_comments_url()
      
        @comment = comments(:pendiente_euskadinet)
        assert @comment.pending?
      end
      
      should "approve comment" do
        # xhr :post, :update_status, :id => @comment.id, :comment => {:status => "aprobado"}
        xhr :post, :update_status, :id => @comment.id, :do_action => "approve"
        assert_response :success
      
        @comment.reload
        assert @comment.approved?
      end

      should "reject comment without email" do
        xhr :post, :do_reject, :id => @comment.id, :return_to => admin_external_comments_path()
        assert_response :redirect
        assert_redirected_to admin_external_comments_path()        
      
        @comment.reload
        assert @comment.rejected?
      end

      should "reject comment with email" do
        assert_difference 'ActionMailer::Base.deliveries.count', 1 do
          xhr :post, :do_reject, :id => @comment.id, :reject_and_mail => "Rechazar y enviar email", :return_to => admin_external_comments_path()
          assert_response :redirect
        end
        assert_redirected_to admin_external_comments_path()
      
        @comment.reload
        assert @comment.rejected?
      end


      should "mark as spam" do      
        xhr :post, :update_status, :id => @comment.id, :do_action => 'mark_as_spam'
        assert_response :success
      
        @comment.reload
        assert @comment.spam?
      end

      should "not delete comment" do      
        assert_no_difference("Comment.count") do
          xhr :post, :destroy, :id => @comment.id
        end      
        assert_not_authorized
      end
      
      should "show comments on item" do
        get :comments_on_item, :id => @comment.commentable_id
        assert_response :success
        
        assert_select "p#comments_status", :text => /Cerrar comentarios en este comentario externo/
      end
      
      should "not close comments on item" do
        assert !@comment.commentable.comments_closed?
        xhr :put, :update_comments_status, :item_id => @comment.commentable_id, :comments_closed =>"true"
        assert_not_authorized
        
        @comment.commentable.reload
        assert !@comment.commentable.comments_closed? 
      end
      
    end
    
  end
end
