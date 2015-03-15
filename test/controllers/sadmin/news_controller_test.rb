require 'test_helper'

class Sadmin::NewsControllerTest < ActionController::TestCase

  ["admin", "jefe_de_prensa", "jefe_de_gabinete", "colaborador", "miembro_que_modifica_noticias"].each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :index
      assert_response :success
      assert_template "index"
    end
  end

  roles = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "redirect if logged as #{role}" do
      login_as(role)
      get :index
      assert_not_authorized
    end
  end


  #
  # Main menu options.
  # Probably the following tests should be put into another test file.
  #
  test "admin menu options" do
    login_as(:admin)
    get :index

    assert_select "div.menu_admin" do
      assert_select "ul" do
        modules = ["Noticias", "Agenda", "Videoteca", "Fototeca", "Páginas"]
        modules << "Peticiones" if Settings.optional_modules.proposals
        modules << "Prop. gobierno" if Settings.optional_modules.debates
        modules << "Streaming" if Settings.optional_modules.streaming
        modules << "Comentarios"
        modules << "Escucha activa" if Settings.optional_modules.headlines
        modules << "Boletines"
        modules.each_with_index do |text, n|
         assert_select "li:nth-child(#{n+1})" do
           assert_select 'a', text
         end
       end
       assert_select "li:nth-child(12)", :count => 0
      end
    end
  end


  test "department editor menu options" do
    login_as(:jefe_de_prensa)
    get :index

    assert_select "div.menu_admin" do
      assert_select "ul" do
        modules = ["Noticias", "Agenda"]
        modules << "Peticiones" if Settings.optional_modules.proposals
        modules << "Comentarios"
        modules.each_with_index do |text, n|
         assert_select "li:nth-child(#{n+1})" do
           assert_select 'a', text
         end
       end
       assert_select "li:nth-child(5)", :count => 0
      end
    end
  end


  test "chief of staff menu options" do
    login_as(:jefe_de_gabinete)
    get :index

    assert_select "div.menu_admin" do
      assert_select "ul" do
        ["Noticias", "Agenda"].each_with_index do |text, n|
         assert_select "li:nth-child(#{n+1})" do
           assert_select 'a', text
         end
       end
       assert_select "li:nth-child(4)", :count => 0
      end
    end
  end

  test "colaborator menu options" do
    login_as(:colaborador)
    get :index

    assert_select "div.menu_admin" do
      assert_select "ul" do
        modules = ["Noticias", "Videoteca", "Fototeca"]
        modules << "Streaming" if Settings.optional_modules.streaming
        modules.each_with_index do |text, n|
          assert_select "li:nth-child(#{n+1})" do
            assert_select 'a', text
          end
        end
        assert_select "li:nth-child(5)", :count => 0
      end
    end
  end

  test "department member home" do
    login_as(:secretaria_interior)

    get :home
    assert_response :redirect
    assert_redirected_to sadmin_events_path
  end


  test "miembro_que_modifica_noticias menu options" do
    login_as(:miembro_que_modifica_noticias)
    get :index
    assert_response :success

    assert_select "div.menu_admin" do
      assert_select "ul" do
        ["Noticias", "Agenda"].each_with_index do |text, n|
         assert_select "li:nth-child(#{n+1})" do
           assert_select 'a', text
         end
       end
       assert_select "li:nth-child(3)", :count => 0
      end
    end
  end

  test "miembro_que_modifica_noticias can edit news" do
    login_as(:miembro_que_modifica_noticias)
    get :edit, :id => documents(:one_news)
    assert_response :success
  end

  test "miembro_que_modifica_noticias cannot create news" do
    login_as(:miembro_que_modifica_noticias)
    get :new
    assert_not_authorized
  end

  test "miembro_que_crea_noticias can also edit news" do
    login_as(:miembro_que_crea_noticias)
    get :show, :id => documents(:one_news).id
    assert_response :success
    # Hay boton de modificar
    assert_select 'ul.edit_links li a', :text => "Modificar", :count => 1
    # Hay boton de añadir documento
    assert_select 'ul.edit_links a#add_attachment[href*=?]', "attachable_type=Document", :text => "Crear documento adjunto", :count => 1

    assert_select 'div.create_update_info'

    # Si intentamos modificarlo, nos deja
    get :edit, :id => documents(:one_news).id
    assert_response :success
    assert_template 'edit'

    put :update, :id => documents(:one_news).id, :news => {:title_es => "cambio titulo"}
    assert_redirected_to sadmin_news_path(documents(:one_news).id)
    assert_equal "La noticia se ha guardado correctamente.", flash[:notice]
  end

  test "get new news form withouf default department" do
    login_as(:admin)
    get :new
    assert_response :success

    assert assigns(:news)
    assert_select "select#news_organization_id" do
      assert_select "option", /Elige/
    end
  end


  test "get new news with relted event" do
    event = documents(:current_event)
    login_as(:admin)
    get :new, :related_event_id => event.id
    assert_response :success

    assert assigns(:news)
    assert_equal [event.id], assigns(:news).event_ids
    assert_equal event.title, assigns(:news).title
    assert_equal event.speaker, assigns(:news).speaker
    assert_equal event.starts_at.to_date.to_s.gsub('-', '/') + '/', assigns(:news).multimedia_dir
    assert_equal event.area_tags, assigns(:news).area_tags
    assert_equal event.politicians_tag_list, assigns(:news).politicians_tag_list
    assert assigns(:news).is_private?

    assert_select 'input#news_event_ids_0[type=hidden][value=?]', event.id
  end

  test "create new news with related event" do
    event = documents(:current_event)
    login_as(:admin)
    now = Time.zone.now
    if event.is_public?
      time_params = {"published_at(1i)".to_sym => now.year.to_s, "published_at(2i)".to_sym => now.month.to_s,
                     "published_at(3i)".to_sym => now.day.to_s, "published_at(4i)".to_sym => now.hour.to_s,
                     "published_at(5i)".to_sym => now.min.to_s}
    else
       time_params = {}
    end

    assert_difference("RelatedEvent.count", 1) do
      post :create, :news => {:organization_id => event.organization_id,
                              :speaker_es => event.speaker_es,
                              :title_es => event.title_es,
                              :event_ids => [event.id]}.merge(time_params)
      assert_response :redirect
    end

    assert assigns(:news)
    assert_equal [event], assigns(:news).events
    assert_equal event.title_eu, assigns(:news).title_eu
    assert_equal event.speaker_eu, assigns(:news).speaker_eu

    assert_equal "La noticia se ha guardado correctamente.", flash[:notice]
  end


  test "create new news with related event should not duplicate politician and area tags" do
    politician_tag = tags(:tag_politician_lehendakaritza)
    lehendakaritza_area = areas(:a_lehendakaritza)
    event = documents(:current_event)
    event.tag_list.add politician_tag.name_es
    assert event.save
    event.reload
    login_as(:admin)

    assert_difference 'News.count', +1 do
      post :create, :news => {:organization_id => event.organization_id,
                            :politicians_tag_list => politician_tag.name_es,
                            :area_tags => [lehendakaritza_area.area_tag.name_es],
                            :speaker_es => event.speaker_es,
                            :title_es => event.title_es,
                            :event_ids => [event.id]}
    end
    assert assigns(:news)

    assert_equal 1, assigns(:news).taggings.where("tag_id = #{politician_tag.id}").count
    assert_equal 1, assigns(:news).taggings.where("tag_id = #{lehendakaritza_area.area_tag.id}").count
  end

  test "one news menu for admin" do
    login_as(:admin)
    news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)

    get :show, :id => news.id
    assert_response :success

    assert_select 'div.one_news_submenu ul' do
      assert_select 'li', 'Contenido principal'
      assert_select 'li', 'Contenido adicional'
      assert_select 'li', 'Traducciones'
      assert_select 'li', 'Subtítulos'
    end

  end

  test "one news menu for colaborador" do
    login_as(:colaborador)
    news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)

    get :show, :id => news.id
    assert_response :success

    assert_select 'div.one_news_submenu ul' do
      assert_select 'li', 'Contenido principal'
      assert_select 'li', 'Contenido adicional'
      assert_select 'li', 'Traducciones'
      assert_select 'li', :text => 'Subtítulos', :count => 0
    end

  end


  ["jefe_de_prensa", "jefe_de_gabinete", "miembro_que_modifica_noticias"].each do |role|
    test "one news menu for #{role}" do
      login_as(role)
      assert !users(role).can?("manage_subtitles", "news")
      news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)

      get :show, :id => news.id
      assert_response :success

      assert_select 'div.one_news_submenu ul' do
        assert_select 'li', 'Contenido principal'
        assert_select 'li', :text => 'Contenido adicional', :count => 0
        assert_select 'li', 'Traducciones'
        assert_select 'li', :text => 'Subtítulos', :count => 0
      end
    end
  end

 if Settings.optional_modules.debates
  context "with debate" do
    setup do
      login_as(:admin)
      @debate = debates(:debate_nuevo)
    end

    should "get new newsxx" do
      get :new, :debate_id => @debate.id
      assert_response :success

      assert assigns(:news)
      assert_equal @debate.title, assigns(:news).title
      assert_equal @debate.organization, assigns(:news).organization
      assert_match "propgob_#{@debate.multimedia_dir}", assigns(:news).multimedia_dir
      assert assigns(:news).is_private?

      assert_select "form input#news_debate_id"
      assert_select "span.debate_news_notice"
    end

    should "create new news" do
      assert_difference("News.count", 1) do
        post :create, :news => {:debate_id       => @debate.id,
                                :organization_id => @debate.organization_id,
                                :title_es        => @debate.title_es,
                                :area_tags       => [@debate.area.area_tag.name_es]}
      end
      assert_response :redirect
      assert_redirected_to sadmin_news_path(:id => assigns(:news).id)

      assert assigns(:news)
      news = assigns(:news)
      news.reload # para cargar correctamente la lista de tags
      assert_equal @debate, news.debate
      # los tags de la noticia son los del debate más el tag del organismo.
      assert_equal (@debate.tag_list + [assigns(:news).organization.tag_name]).sort, news.tag_list.sort

      assert_equal "La noticia se ha guardado correctamente.", flash[:notice]
    end

    should "show new form if news is not valid" do
      assert_no_difference("News.count") do
        post :create, :news => {:debate_id       => @debate.id,
                                :organization_id => @debate.organization_id,
                                :title_es        => nil,
                                :area_tags       => [@debate.area.area_tag.name_es]}
      end
      assert_response :success
      assert_template "new"

      assert assigns(:news)
      assert_equal @debate, assigns(:news).debate

      assert_select "div#errorExplanation"
      assert_select "form input#news_debate_id"
    end

    should "show news with debate info" do
      get :show, :id => documents(:news_for_debate).id
      assert_response :success

      assert_select "span.debate_news_notice"
    end
  end
 end

  context "epub" do
    setup do
      login_as("admin")
    end

    should "choose criterio" do
      get :choose_criterio
      assert_response :success
      assert_select 'form[action=new_epub]' do
        assert_select 'input#criterio_id'
      end
    end

    should "render new_epub" do
      get :new_epub, :criterio_id => criterios(:criterio_one)
      if elasticsearch_available?
        assert_template 'new_epub'
        assert assigns(:search_results)
        assert_select 'form[action=create_epub]' do
          assert_select 'input[type=checkbox]', :count => assigns(:search_results).length + 1
        end
      else
        assert_response :redirect
        assert_equal I18n.t('search.servidor_no_disponible'),  flash[:error]
      end
    end

    should "create epub" do
      export_dir = File.join(Rails.root, "test", "data", "epub")
      assert !File.exists?(File.join(export_dir, "irekia-epub.zip"))
      post :create_epub, :news_to_export => [FactoryGirl.create(:published_news).id], :export_dir => export_dir
      assert_response :success
      assert File.exists?(File.join(export_dir, "irekia-epub.zip"))
      FileUtils.rm_r(export_dir)
    end
  end

end
