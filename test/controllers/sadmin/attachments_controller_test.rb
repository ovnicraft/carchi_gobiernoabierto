require 'test_helper'

class Sadmin::AttachmentsControllerTest < ActionController::TestCase
  
  test "unlogged user should be redirected" do
    get :new, :attachable_id => documents(:one_news), :attachable_type => 'Document'
    assert_redirected_to new_session_path
  end
  
  roles = ["periodista", "visitante", "comentador_oficial", "secretaria_interior"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "redirect if logged as #{role}" do
      login_as(role)
      get :new, :attachable_id => documents(:one_news).id, :attachable_type => 'Document'
      assert_not_authorized
    end
  end
  
  test "redirect if logged as colaborador and tries to add attachment to event" do
    login_as("colaborador")
    get :new, :attachable_id => documents(:passed_event).id, :attachable_type => 'Document'
    assert_not_authorized
  end
  
  roles = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", \
   "jefe_de_gabinete", "jefe_de_prensa", "colaborador", "miembro_que_modifica_noticias", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
     test "redirect if logged as #{role} and tries to add attachment to page" do
       login_as(role)
       get :new, :attachable_id => documents(:page_in_menu).id, :attachable_type => 'Document'
       assert_not_authorized     
     end     
  end
    
  test 'should get new document' do
    login_as(:jefe_de_gabinete)
  
    get :new, :attachable_id => documents(:current_event).id, :attachable_type => 'Document'
    assert_response :success
    
    assert_select "div.menu_admin ul li.active", :text => "Agenda"
  end
  
 if Settings.optional_modules.proposals
  test 'should get new proposal' do
    login_as(:admin)
  
    get :new, :attachable_id => proposals(:governmental_proposal).id, :attachable_type => 'Proposal'
    assert_response :success
    
    assert_select "div.menu_admin ul li.active", :text => I18n.t('admin.menu.propuestas')
  end
 end

 if Settings.optional_modules.debates
  test 'should get new debate' do
    login_as(:admin)
  
    get :new, :attachable_id => debates(:debate_completo).id, :attachable_type => 'Debate'
    assert_response :success
    
    assert_select "div.menu_admin ul li.active", :text => I18n.t('admin.menu.debates')
  end
  
  test "should create debate attachment and redirect" do
    login_as(:admin)
    
    debate = debates(:debate_completo)
    file = Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "test.txt"), 'text/txt')
    put :create, :attachable_id => debate.id, :attachable_type => 'Debate', :attachment => {:file => file}
    assert_redirected_to admin_debate_path(debate)
    assert 1, debate.attachments.count

    # clean test assets
    debate.attachments.each do |att|
      assert FileUtils.rm_rf(File.dirname(att.file.path))
    end
  end
 end
  
  test 'should get edit' do
    login_as(:jefe_de_gabinete)
  
    e = documents(:current_event)
    file = Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "test.txt"), 'text/txt')
    e.attachments.create(:file => file, :attachable_type => 'Document', :attachable_id => e.id)
  
    get :edit, :id => e.attachments.first.id 
    assert_response :success
    
    assert_select "div.menu_admin ul li.active", :text => "Agenda"
    # clean test assets
    e.attachments.each do |att|
      assert FileUtils.rm_rf File.dirname(att.file.path)
    end
  end

  test "miembro_que_crea_noticias can also add attachments" do
    login_as(:miembro_que_crea_noticias)
    get :new, :attachable_id => documents(:one_news).id, :attachable_type => 'Document'
    assert_response :success
    assert_template 'new'
    file = Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "test.txt"), 'text/txt')
    put :create, :attachable_id => documents(:one_news).id, :attachable_type => 'Document', :attachment => {:file => file}
    assert_redirected_to sadmin_news_path(documents(:one_news))
    assert 1, documents(:one_news).attachments.count
    
    # Now we modify visibility
    get :edit, :id => documents(:one_news).attachments.first.id
    assert_response :success
    assert_template 'edit'
    assert_select "div.menu_admin ul li.active", :text => "Noticias"
    
    put :update, :id => documents(:one_news).attachments.first.id, :attachment => {:show_in_eu => "1"}
    assert_redirected_to sadmin_news_path(documents(:one_news))
    assert_equal "El documento adjunto se ha guardado correctamente.", flash[:notice]
    assert documents(:one_news).attachments.first.show_in_eu?
    
    # Now, we can delete the recently created attachment
    att_file_path = documents(:one_news).attachments.first.file.path
    delete :destroy, :id => documents(:one_news).attachments.first.id
    assert_redirected_to sadmin_news_path(documents(:one_news))
    assert_equal "El documento adjunto se ha eliminado correctamente.", flash[:notice]

    # clean test assets
    assert FileUtils.rm_rf File.dirname(att_file_path)
  end  

end
