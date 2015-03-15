require 'test_helper'

class Admin::DebatesControllerTest < ActionController::TestCase
 if Settings.optional_modules.debates
  def setup 
    login_as('admin')
    ActionMailer::Base.deliveries = []
  end
  
  def teardown
    FileUtils.rm_rf(Dir["#{Rails.root}/test/uploads/debate"])
  end

  context "debates list" do
    setup do
      get :index
    end

    should "respond_with success" do
      assert_response :success
    end
    
    should "show create debate link" do
      assert_select "ul.edit_links li a", :text => "Crear propuesta"
    end

    should "show submenu with Arguments link" do
      assert_select "div.submenu" do
        assert_select "ul" do
          assert_select "li", :count => 3
          assert_select "li", :text => "Propuestas"
          assert_select "li a", :text => "Argumentos"
          assert_select "li a", :text => "Entidades"
        end
      end
    end
  end
  
  context "arguments" do
    setup do
      get :arguments
    end

    should "respond_with success" do
      assert_response :success
    end
    
    should "contain only debate arguments" do
      assert assigns(:arguments).length > 0
      assert_nil assigns(:arguments).detect {|a| a.argumentable.is_a?(Proposal)}
    end
  end
  
  context "new debate" do
    setup do
      get :new
    end
    
    should "respond_with success" do
      assert_response :success
    end
    
    should "initialize debate stages" do
      assert assigns(:debate)
      assert_equal 4, assigns(:debate).stages.length
      
      assert_select "div.debate_fases table.admin" do
        assert_select "tr th", :text => "Presentación"
        assert_select "tr th", :text => "Debate"        
        assert_select "tr th", :text => "Aportaciones"          
        assert_select "tr th", :text => "Conclusiones"        
      end
    end
    
  end
  
  context "create debate" do
    setup do
      @debate_params = {:title_es => "Título en castellano del debate", 
                        :body_es => "Introducción en castellano", 
                        :description_es => "Descripción en castellano",
                        :stages_attributes => [{"label" => "presentation", 
                                                           "starts_on(3i)" => "1", "starts_on(2i)" => "1", "starts_on(1i)" => "2013", 
                                                           "ends_on(3i)" => "1", "ends_on(2i)" => "2", "ends_on(1i)" => "2013"},
                                               {"label" => "discussion", 
                                                           "starts_on(3i)" => "1", "starts_on(2i)" => "2", "starts_on(1i)" => "2013", 
                                                           "ends_on(3i)" => "1", "ends_on(2i)" => "3", "ends_on(1i)" => "2013"},                                                           
                                               {"label" => "contribution", 
                                                           "starts_on(3i)" => "1", "starts_on(2i)" => "3", "starts_on(1i)" => "2013", 
                                                           "ends_on(3i)" => "1", "ends_on(2i)" => "4", "ends_on(1i)" => "2013"},                                                           
                                               {"label" => "conclusions", 
                                                           "starts_on(3i)" => "1", "starts_on(2i)" => "4", "starts_on(1i)" => "2013", 
                                                           "ends_on(3i)" => "1", "ends_on(2i)" => "5", "ends_on(1i)" => "2013"}  
                                              ],
                        :organization_id => organizations(:lehendakaritza).id,
                        :hashtag => "#debate1",
                        :tag_list_without_hashtag => areas(:a_lehendakaritza).tag_name_es,
                        :multimedia_dir => "debate1",
                        :draft => 1
                       }
    end
    
    should "save debate and redirect" do
      assert_difference("Debate.count", 1) do
        post :create, :debate => @debate_params
      end
      assert_response :redirect
      assert_not_nil assigns(:debate).created_by
    end
    
    should "not save debate and show new form" do
      assert_no_difference("Debate.count") do
        post :create, :debate => @debate_params.merge!( {:title_es => nil} )
      end
      assert_response :success
      assert_template "new"
      
    end
    
  end

  context "with debate" do
    setup do
      @debate = debates(:debate_completo)
      assert @debate.entities.present?
    end
    
    context "show debate" do
      setup do
        get :show, :id => @debate.id
      end
    
      should "respond_with success" do
        assert_response :success
      end
    
      should "show submenu" do
        assert_select "div.one_news_submenu" do
          assert_select "li", :text => "Contenido principal"
          assert_select "li", :text => "Contenido adicional"        
          assert_select "li", :text => "Traducciones"        
        end  
      end
    
      should "show entities" do
        assert_select "div#debate_entities" do
          assert_select "h2", "Entidades relacionadas"
          assert_select "ul#entities_list" do
            assert_select "li", :text => /#{outside_organizations(:organization_for_debate).name}/
          end 
          assert_select "ul.edit_links" do
            assert_select "li", :text => /Añadir entidad/
          end
        end
      end
    
      should "show attachements" do
        assert_select "div#debate_attachments" do
          assert_select "h2", "Documentos adjuntos"
          assert_select 'ul.edit_links a#add_attachment[href*=?]', "attachable_type=Debate", :text => "Crear documento adjunto", :count => 1
        end
      end
    
    
      should "show published_notice for published debate" do
        assert @debate.published?
        assert_select "span.published_notice", /Esta propuesta está publicada/
      end

      should "show finished_notice for finished debate" do
        assert @debate.published?
        assert_select "span.published_notice", /Esta propuesta ha finalizado/
      end

    end
    
    context "show unpublished debate" do
      setup do
        @debate.stages.each do |st|
          st.update_attributes(:starts_on => st.starts_on + 10.year, :ends_on => st.ends_on + 10.year)
        end
        assert @debate.save
        assert_equal @debate.presentation_stage.starts_on, @debate.published_at.to_date
        assert @debate.is_public?        
        assert !@debate.published?
        get :show, :id => @debate.id
      end
      
      should "show unpublished_notice" do
        assert_select "span.unpublished_notice"
      end
      
    end

    context "show common info" do
      setup do
        get :common, :id => @debate.id
      end
      should "respond_with success" do
        assert_response :success
      end
            
    end

    context "show translations" do
      setup do
        get :translations, :id => @debate.id
      end
      should "respond_with success" do
        assert_response :success
      end
      
      should "show submenu" do
        assert_select "div.one_news_submenu"
      end
      
      should "show edit link" do
        assert_select "ul.edit_links" do
          assert_select "li a.edit[href*=?]", /\/admin\/debates\//
        end
      end
            
    end
          
    context "edit debate" do
      setup do
        get :edit, :id => @debate.id
      end

      should "respond_with success" do
        assert_response :success
      end
      
      should "show descpription fileds for presentation and discussion" do
        assert_select "table.admin" do
          assert_select "th", :text => /Introducción fase Presentación/
          assert_select "th", :text => /Descripción fase Debate/
        end
      end 
      
      context "with removed stages" do
        setup do
          @debate.contribution_stage.destroy
        end
        
        should "show all stages" do
          get :edit, :id => @debate.id
          
          assert_select "div.debate_fases" do
            assert_select "table tr", :count => 4
          end
        end
        
      end 
    end
    
    context "debate with department that is no more active" do
      setup do
        @debate_viejo = debates(:debate_viejo)
        assert !@debate_viejo.organization.active?
      end
      
      should "edit debate with full list of depts" do
        get :edit, :id => @debate_viejo.id
        assert_response :success
        assert_select "select#debate_organization_id" do
          assert_select "option", :text => @debate_viejo.organization.name
        end
      end
    end
    
    
    context "edit common info" do
      setup do
        get :edit_common, :id => @debate.id
      end
      should "respond_with success" do
        assert_response :success
      end
    end
    
    context "edit translations" do
      setup do
        get :edit, :id => @debate.id, :w => "traducciones", :lang => "eu"
      end
      should "respond_with success" do
        assert_response :success
      end
      
      should "set hidden values" do
        assert_select "input#redirect_to"
        assert_select "input#w"
        assert_select "input#lang"        
      end
      
      should "show only translatable fields" do
        assert_select "input#debate_title_eu"
        assert_select "td#body_eu_container"        
        assert_select "td#description_eu_container"                
        
        assert_select "select#debate_organization_id", :count => 0
        assert_select "input#debate_hashtag", :count => 0
        assert_select "div.debate_fases", :count => 0
        assert_select "input#debate_draft", :count => 0
        assert_select "p#publication_date", :count => 0
      end
    end
  
    context "update debate" do
      setup do
        @debate = debates(:debate_completo)
      end
    
      should "update and redirect" do
        put :update, :id => @debate.id, :debate => {:title_es => "Título en castellano del debate", 
                          :body_es => "Introducción en castellano", 
                          :description_es => "Descripción en castellano",
                          :organization_id => organizations(:lehendakaritza).id,
                          :hashtag => "nuevohashtag"}
        assert_response :redirect
        assert_redirected_to admin_debate_path(assigns(:debate))        
      end
      
      should "not update and show edit" do
        put :update, :id => @debate.id, :debate => {:title_es => nil}
        assert_response :success
        assert_template "edit"
      end
      
      should "update stages dates" do
        put :update, :id => @debate.id, 
                     :debate => {:stages_attributes =>  {"0"=>{"starts_on(1i)"=>"2013", "starts_on(2i)"=>"7", "starts_on(3i)"=>"9", 
                                                               "ends_on(1i)"=>"2013", "ends_on(2i)"=>"7", "ends_on(3i)"=>"9",                        
                                                               "label"=>"presentation", "id" => @debate.presentation_stage.id}, 
                                                         "1"=>{"starts_on(1i)"=>"2013", "starts_on(2i)"=>"8", "starts_on(3i)"=>"9",
                                                               "ends_on(1i)"=>"2013", "ends_on(2i)"=>"8", "ends_on(3i)"=>"9",
                                                               "label"=>"discussion",  "id"=>@debate.discussion_stage.id},
                                                         "2"=>{"starts_on(1i)"=>"2013", "starts_on(2i)"=>"9", "starts_on(3i)"=>"9",
                                                               "ends_on(1i)"=>"2013", "ends_on(2i)"=>"9", "ends_on(3i)"=>"9",
                                                               "label"=>"contribution",  "id"=>@debate.contribution_stage.id},
                                                         "3"=>{"starts_on(1i)"=>"2013", "starts_on(2i)"=>"10", "starts_on(3i)"=>"9",   
                                                               "ends_on(1i)"=>"2013", "ends_on(2i)"=>"11", "ends_on(3i)"=>"9",
                                                               "label"=>"conclusions", "id"=>@debate.conclusions_stage.id }}}
        assert_response :redirect
        assert_redirected_to admin_debate_path(assigns(:debate))
      end
    end

    context "update common info" do
      setup do
        @debate = debates(:debate_completo)
      end
    
      should "update and redirect" do
        put :update, :id => @debate.id, :debate => {:tag_list_without_hashtag => @debate.tag_list_without_hashtag.to_s + ", #{tags(:tagueado).name_es}"}, :redirect_to => common_admin_debate_path(@debate)
        assert_response :redirect
        assert_redirected_to common_admin_debate_path(@debate)
      end
    end

    context "update translations" do
      setup do
        @debate = debates(:debate_completo)
      end
    
      should "update and redirect" do
        put :update, :id => @debate.id, :lang => "eu", :locale =>"es", :debate => {:body_eu => "<p>Laburpena</p>", "title_eu"=>"Euskaraz", "description_eu"=>"<p>Describapena</p>"}, :redirect_to => translations_admin_debate_path(@debate)
        assert_response :redirect
        assert_redirected_to translations_admin_debate_path(@debate)
      end
    end
  
    context "destroy debate" do
      setup do
        @debate = debates(:debate_completo)
      end

      should "destroy debate" do
        assert_difference "Debate.count", -1 do
          assert_difference "DebateStage.count", -4 do
            assert_difference "DebateEntity.count", -1 do
              delete :destroy, :id => @debate.id
            end
          end
        end
        assert_response :redirect
      end    
    end
    
  end
 end
end
