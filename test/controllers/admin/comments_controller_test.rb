require 'test_helper'

class Admin::CommentsControllerTest < ActionController::TestCase
  test "unlogged user should not be redirected" do
    get :index
    assert_not_authorized
  end
  
  ["admin", "jefe_de_gabinete", "jefe_de_prensa"].each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :index
      assert_response :success
      assert_template "index"
    end
  end
  
  roles = ["periodista", "visitante", "secretaria_interior", "miembro_que_modifica_noticias", "colaborador", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :index
       assert_not_authorized     
     end     
  end
  
  ["jefe_de_gabinete", "jefe_de_prensa"].each do |role|
    test "#{role} cannot edit comments" do
      login_as(role)
      get :edit, :id => comments(:aprobado_castellano).id
      assert_not_authorized
    end
  end  
  
  ["jefe_de_gabinete", "jefe_de_prensa"].each do |role|
    test "#{role} cannot update comments" do
      login_as(role)
      put :update, :id => comments(:aprobado_castellano).id, :comment => {:body => "changed"}
      assert_not_authorized
    end
  end
  
  test "admin can edit comment" do
    login_as("admin")
    get :edit, :id => comments(:aprobado_castellano).id
    assert_response :success
    assert_template "edit"
  end
  
  test "admin can update comment" do
    login_as("admin")
    put :update, :id => comments(:aprobado_castellano).id, :comment => {:body => "changed"}
    assert_redirected_to admin_comments_path
  end
  
  test "should not list other departments comments when department is selected" do
    login_as(:admin)
    get :index, :dep_id => organizations(:interior).id
    assert_response :success
    assert_select 'h2', "Comentarios del departamento Interior"
    assert !assigns(:comments).include?(comments(:aprobado_castellano))
  end
  
  test "should list comments belonging to my department if i am logged in as a department editor" do
    login_as(:jefe_de_prensa)
    get :index
    assert_response :success
    assert_select 'h2', "Comentarios del departamento Presidencia"
    # All comments of resources tagged with '_lehendakaritza' tag should be listed
    documents_with_lehendakaritza_tag = Document.tagged_with(organizations(:lehendakaritza).tag_name, :any => true)
    comments_on_documents_with_lehendakaritza_tag = Comment.where("commentable_type='Document' AND commentable_id in (#{documents_with_lehendakaritza_tag.collect(&:id).join(', ')})")
    comments_on_documents_with_lehendakaritza_tag.each do |doc_comment|
      assert assigns(:comments).include?(doc_comment), "Comment ##{doc_comment.id} on document #{doc_comment.commentable_id} should be listed but it is not"
    end
    
    videos_with_lehendakaritza_tag = Video.tagged_with(organizations(:lehendakaritza).tag_name, :any => true)
    comments_on_videos_with_lehendakaritza_tag = Comment.where("commentable_type='Video' AND commentable_id in (#{videos_with_lehendakaritza_tag.collect(&:id).join(', ')})")
    comments_on_videos_with_lehendakaritza_tag.each do |video_comment|
      assert assigns(:comments).include?(video_comment), "Comment ##{video_comment.id} on video #{video_comment.commentable_id} should be listed but it is not"
    end
    
    assert !assigns(:comments).include?(comments(:aprobado_de_interior)), "El comentario de la noticia de interior no debería estar ahí"
  end
  

end
