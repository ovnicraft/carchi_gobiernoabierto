require 'test_helper'

class Admin::DocumentsControllerTest < ActionController::TestCase
  
  test "unlogged user should not be redirected" do
    get :index
    assert_not_authorized
  end
  
  ["admin", "colaborador", "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias"].each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :show, :id => documents(:one_news), :w => "traducciones"
      assert_response :success
      assert_template "admin/documents/show"
      
     assert_select "ul.edit_links" do
       assert_select "li a.edit[href*=?]", /\/admin\/documents\//
     end
    end
  end
  
  users = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", "room_manager"]
  users << "operador_de_streaming" if Settings.optional_modules.streaming
  users.each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :index
       assert_not_authorized     
     end     
  end
   
  test "index for admin" do
    login_as(:admin)
    
    # El index lleva al tab Noticias
    get :index
    assert_response :redirect
    assert_redirected_to sadmin_news_index_path
    
    
    get :index, :t => "event"
    assert_response :redirect
    assert_redirected_to sadmin_events_path
  end 
  
  test "show event more_info page" do
    login_as(:admin)
    get :show, :id => documents(:emakunde_passed_event), :w => 'more_info'
    assert_response :success
    
    assert_select 'div.coverage' do
      assert_select 'span', I18n.t('events.irekia_covered', :site_name => Settings.site_name, :cov_types => I18n.t('events.irekia_coverage_article')).mb_chars.upcase.to_s + '.'
    end
    
    assert_select 'span.category_tags'
    assert_select 'p', /#{I18n.t('admin.events.cobertura_irekia', :site_name => Settings.site_name)}/
    
    assert_select 'p', /Fotos/
    assert_select 'p', /Vídeos/
    assert_select 'p', /Audio/
    assert_select 'p', /Crónica/
    assert_select 'p', /Streaming/

  end

  test "edit event tags" do
    login_as(:admin)

    get :edit_tags, :id => documents(:current_event).id, :w => 'more_info'
    assert_response :success

    assert_select 'select#document_area_tags_'
    assert_select 'textarea#document_tag_list_without_areas'
    assert_select 'input#document_irekia_coverage'

    assert_select 'div.select_webs' do
      assert_select 'label', 'Fotos'
      assert_select 'label', 'Vídeos'
      assert_select 'label', 'Audio'
      assert_select 'label', 'Crónica'
    end

  end

 if Settings.optional_modules.streaming
  test "edit event tags with streaming" do
    login_as(:admin)

    get :edit_tags, :id => documents(:event_with_streaming).id, :w => 'more_info'
    assert_select 'input#document_streaming_live'
    assert_select 'input#document_streaming_for_irekia'
    assert_select 'input#document_streaming_for_en_diferido'

    assert assigns(:overlap_events_with_streaming)
    assert_equal 2, assigns(:overlap_events_with_streaming).size
    [:event_with_streaming_without_alerts, :event_with_streaming_and_sent_alert_and_show_in_irekia].each do |key|
      assert assigns(:overlap_events_with_streaming).detect {|evt| evt.eql?(documents(key))}, "#{key} not found in the list of overlapping events."
    end

  end
 end

  test "should show create draft news checkbox if no related news is given" do
    login_as(:admin)
    
    get :edit_tags, :id => documents(:current_event).id, :w => 'more_info'
    assert_response :success

    assert_select 'input#document_draft_news'    
  end
  
  test "should not show create drft news if related news is present" do
    login_as(:admin)
    get :edit_tags, :id => documents(:emakunde_passed_event).id, :w => 'more_info'
    
    assert_select 'input#document_draft_news', :count => 0
  end
  
  
  test "update event more info" do
    login_as(:admin)
    evt = documents(:current_event)
    
    assert !evt.irekia_coverage_audio?
    assert !evt.irekia_coverage_video?
    assert !evt.irekia_coverage_photo?
    
    get :update, :id => evt.id, :document => {:irekia_coverage_photo => "1", :irekia_coverage_video => "1", :irekia_coverage_audio => "1"}
    assert_response :redirect
    assert_redirected_to  admin_document_path(evt.id)
 
    evt = assigns(:document)
    assert evt.irekia_coverage_audio?
    assert evt.irekia_coverage_video?
    assert evt.irekia_coverage_photo?
  end

 if Settings.optional_modules.streaming
  test "update event more info with streaming" do
    login_as(:admin)
    evt = documents(:event_with_streaming)
    
    assert !evt.irekia_coverage_audio?
    assert !evt.irekia_coverage_video?
    assert !evt.irekia_coverage_photo?
    assert evt.streaming_for_irekia?
    assert !evt.streaming_for_en_diferido?        
    
    get :update, :id => evt.id, :document => {:irekia_coverage_photo => "1", :irekia_coverage_video => "1", :irekia_coverage_audio => "1", :stream_flow_id => stream_flows(:sf_two).id, :streaming_for_irekia => "0", :streaming_for_en_diferido => "1"}
    assert_response :redirect
    assert_redirected_to  admin_document_path(evt.id)
 
    evt = assigns(:document)
    assert evt.irekia_coverage_audio?
    assert evt.irekia_coverage_video?
    assert evt.irekia_coverage_photo?
    assert !evt.streaming_for_irekia?
    assert evt.streaming_for_en_diferido?        
  end
  end

  test "update event more info when draft news checkbox is checked" do
    login_as(:admin)
    evt = documents(:future_event)
    
    assert_nil evt.related_news_title
    
    assert !evt.irekia_coverage_audio?
    assert !evt.irekia_coverage_video?
    assert !evt.irekia_coverage_photo?
    assert !evt.streaming_for_irekia?
    assert !evt.streaming_for_en_diferido?        
    
    get :update, :id => evt.id, :document => {:irekia_coverage_photo => "1", :irekia_coverage_video => "1", :irekia_coverage_audio => "1", :draft_news => "1"}
    assert_response :redirect
    assert_redirected_to new_sadmin_news_path(:related_event_id => evt.id)
 
    evt = assigns(:document)
    assert evt.irekia_coverage_audio?
    assert evt.irekia_coverage_video?
    assert evt.irekia_coverage_photo?
    assert !evt.streaming_for_irekia?
    assert !evt.streaming_for_en_diferido?        
  end



 if Settings.optional_modules.streaming
  test "do update event more info if web overlap is found" do
    login_as(:admin)
    evt = documents(:event_with_streaming)
    
    put :update, :id => evt.id, :document => {:irekia_coverage_photo => "1", :irekia_coverage_video => "1", :irekia_coverage_audio => "1", :stream_flow_id => stream_flows(:sf_two).id, :streaming_for_irekia => "1", :streaming_for_en_diferido => "0"}, :locale => "es", :return_to=>"edit_tags"
    assert_response :redirect
    assert_redirected_to admin_document_path(evt.id)
    
    evt = assigns(:document)
    assert_not_nil evt.overlapped_streaming.detect {|e| e.eql?(documents(:event_with_streaming_without_alerts))}
  end

  test "do not update event more info if streaming room overlap is found" do
    login_as(:admin)
    evt = documents(:event_with_streaming)
    
    get :update, :id => evt.id, :document => {:irekia_coverage_photo => "1", :irekia_coverage_video => "1", :irekia_coverage_audio => "1", :stream_flow_id => stream_flows(:sf_one).id, :streaming_for_irekia => "1", :streaming_for_en_diferido => "0"}, :locale => "es", :return_to=>"edit_tags"
    assert_response :success
    assert_template "admin/documents/edit_tags"
    
    assert_select "span.field_with_errors", "Sala de Streaming:"
    assert_select "span.error_message", /está ocupada/i

    evt = assigns(:document)
  end

  test "do not update event more info if streaming_for is empty" do
    login_as(:admin)
    evt = documents(:event_with_streaming)
    
    get :update, :id => evt.id, :document => {:irekia_coverage_photo => "1", :irekia_coverage_video => "1", :irekia_coverage_audio => "1", :stream_flow_id => evt.stream_flow_id, :streaming_for_irekia => "0", :streaming_for_en_diferido => "0"}, :locale => "es", :return_to=>"edit_tags"
    assert_response :success
    assert_template "admin/documents/edit_tags"
    
    assert_select "span.field_with_errors", "Streaming en:"
    assert_select "span.error_message", /no puede estar vacío/i
 
    evt = assigns(:document)
  end

  test "change event streaming_live to false" do
    login_as(:admin)
    evt = documents(:event_with_streaming)
    
    assert !evt.irekia_coverage_audio?
    assert !evt.irekia_coverage_video?
    assert !evt.irekia_coverage_photo?
    assert evt.streaming_for_irekia?
    assert !evt.streaming_for_en_diferido?
    
    get :update, :id => evt.id, :document => {:irekia_coverage_photo => "1", :irekia_coverage_video => "1", :irekia_coverage_audio => "1", :streaming_live => "0"}
    assert_response :redirect
    assert_redirected_to admin_document_path(evt.id)
 
    evt = assigns(:document)
    assert evt.irekia_coverage_audio?
    assert evt.irekia_coverage_video?
    assert evt.irekia_coverage_photo?
    assert !evt.streaming_live?
    assert !evt.streaming_for_irekia?
    assert !evt.streaming_for_en_diferido?
  end
 end

  test "tags autocomplete shows all matcing tags" do
    login_as(:admin)
    
    get :auto_complete_for_document_tag_list_without_areas, :document => {:tag_list_without_areas => "educar"}
    assert_response :success
    
    assert assigns(:tags)
    assert_equal tags(:tag_empieza_por_educar).name_es, assigns(:tags).first.name_es
    assert_equal tags(:tag_contiene_educar).name_es, assigns(:tags).last.name_es    
    
  end

 if Settings.optional_modules.debates
  context "with debate" do
    setup do
      login_as(:admin)
      @debate = debates(:debate_nuevo)
    end
    
    should "show new page with debate data" do
      get :new, :lang => "es", :t => "Page", :debate_id => @debate.id
      assert_response :success
      
      assert assigns(:document)
      assert_equal @debate.title_es, assigns(:document).title_es
      
      assert_select "form input#document_debate_id"
      assert_select "span.debate_page_notice"      
    end
    
    should "create page for debate" do
      assert_difference "Page.count", 1 do
        post :create, :t => "pages", :lang => "es", :locale => "es", 
                      :document => {:debate_id => @debate.id, :title_es => @debate.title_es, :body_es => "Contenido de la página", 
                                    :multimedia_dir => "aportaciones_#{@debate.multimedia_dir}", 
                                    :tag_list_without_areas => @debate.tag_list_without_areas.to_s, 
                                    :organization_id => @debate.organization_id}
      end      
      assert_response :redirect
      assert_redirected_to admin_document_path(:id => assigns(:document).id)
      
      @debate.reload
      
      assert_equal assigns(:document), @debate.page
    end

    should "show new page form if page is not valid" do
      assert_no_difference "Page.count" do
        post :create, :t => "pages", :lang => "es", :locale => "es", 
                      :document => {:debate_id => @debate.id, 
                                    :title_es => nil, 
                                    :body_es => "Contenido de la página", 
                                    :multimedia_dir => "aportaciones_#{@debate.multimedia_dir}", 
                                    :tag_list_without_areas => @debate.tag_list_without_areas.to_s, 
                                    :organization_id => @debate.organization_id}
      end      
      assert_response :success
      assert_template "admin/documents/new"
      
      @debate.reload
      assert_select "form input#document_debate_id"
      assert_select "span.debate_page_notice"
    end

    
    should "show page" do
      get :show, :id => documents(:debate_page).id
      assert_response :success
      
      assert_select "span.debate_page_notice"
    end

    should "edit page" do
      get :edit, :id => documents(:debate_page).id, :t => "Page", :lang => 'es'
      assert_response :success
      
      assert_select "span.debate_page_notice"
    end
  end
 end
end

