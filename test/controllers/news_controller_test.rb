require 'test_helper'

class NewsControllerTest < ActionController::TestCase

  test "get index" do
    get :index
    assert_response :success
  end

  test "get news for area" do
    get :index, :area_id => areas(:a_lehendakaritza).id
    assert_response :success

    assert_equal [areas(:a_lehendakaritza).id], (assigns(:news) + [assigns(:leading_news)]).map {|doc| doc.area_id}.uniq
  end

  test "show commentable news" do
    get :show, :id => documents(:commentable_news).id
    assert_response :success
    assert_select 'div.textarea-comment' do
      assert_select 'span.holder', /comenta esta noticia/
    end
  end

  test "show non-commentable news" do
    get :show, :id => documents(:non_commentable_news).id
    assert_response :success
    assert_select 'div.comment_row' do
      assert_select 'span.comments_closed'
    end
  end

  # test "should show comments in any language" do
  #   get :show, :id => documents(:commentable_news).id
  #   assert_response :success
  #   assert_select 'div.comments ul' do
  #     assert_select 'li', :count => documents(:commentable_news).comments.approved.count + 1
  #     assert_select 'li.comment div.quote p', /aprobado en castellano/
  #     assert_select 'li.comment div.quote p', /aprobado en euskera/
  #     assert_select 'li.comment div.quote p', /Comentario oficial/
  #     assert_select 'li.form', /comenta esta noticia/
  #   end
  # end

  test "should show comments in any language and for any client" do
    news = documents(:commentable_news)
    all_comments = news.comments.approved + external_comments_items(:euskadinet_item_commentable_irekia_news).comments.approved + external_comments_items(:euskadinet_item_commentable_irekia_news_eu).comments.approved

    get :show, :id => news.id
    assert_response :success
    assert_select 'div.comments ul' do
      assert_select 'li', :count => all_comments.length + 1
      assert_select 'li.comment div.quote p', /aprobado en castellano/
      assert_select 'li.comment div.quote p', /aprobado en euskera/
      assert_select 'li.comment div.quote p', /Comentario oficial/
      assert_select 'li.comment div.quote p', /Comentario en euskadi.net en castellano/
      assert_select 'li.comment div.quote p', /Comentario en euskadi.net en euskera/
      assert_select 'li.form', /comenta esta noticia/
    end
  end


  test "translated news should be listed" do
    get :index, :locale => "eu"
    assert_response :success
    assert assigns(:news).detect {|e| e.id.eql?(documents(:translated_news).id)}, "Translated news should be listed"
  end

  test "untranslated news should not be listed" do
    get :index, :locale => "eu"
    assert_response :success
    assert !assigns(:news).detect {|e| e.id.eql?(documents(:untranslated_news).id)}, "Untranslated news should not be listed"
  end

  test "should show translation missing message" do
    get :show, :id => documents(:untranslated_news).id, :locale => "eu"
    assert_response :success

    assert !assigns(:document).translated_to?('eu')
    assert_select 'div.traslation_missing'
  end

  test "untranslated_to_es_news should not be listed" do
    get :index
    assert !assigns(:news).include?(documents(:untranslated_to_es_news))
  end

  %w(superadmin admin jefe_de_prensa jefe_de_gabinete secretaria comentador_oficial).each do |role|
    test "#{role} should be able fill comments form and to change his name when commenting" do
      login_as(role)
      get :show, :id => documents(:commentable_news).id
      assert_response :success
      assert_select 'div.comments ul' do
        assert_select 'li.form' do
          assert_select 'form' do
            assert_select 'input#comment_name'
            assert_select 'textarea#comment'
          end
        end
      end
    end
  end

  %w(periodista visitante twitter_user colaborador).each do |role|
    test "#{role} should be able to fill comments form but not to change his name when commenting" do
      login_as(role)
      get :show, :id => documents(:commentable_news).id
      assert_response :success
      assert_select 'div.comments ul' do
        assert_select 'li.form' do
          assert_select 'form' do
            assert_select 'input#comment_name', :count => 0
            assert_select 'textarea#comment'
          end
        end
      end
    end
  end

  roles = %w(miembro_que_crea_noticias room_manager)
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "#{role} should not be able to fill comments form" do
      login_as(role.to_sym)
      get :show, :id => documents(:commentable_news).id
      assert_response :success
      assert_select 'div#comment_row', :count => 0
    end
  end

  test "should show news with new design for news with multimedia" do
    news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)
    prepare_content_for_news_with_multimedia(news)

    assert news.public_tags_without_politicians.include?(tags(:tag_prueba))
    get :show, :id => news.id
    assert_response :success

    assert assigns(:videos).size > 0, "La noticia tiene que tener por lo menos un vídeo"
    assert assigns(:photos).size > 0, "La noticia tiene que tener por lo menos una foto"

    assert_select 'div.photo_video_viewer' do
      assert_select 'ul.nav li:first-child', :text => "vídeos"
      assert_select 'ul.nav li:nth-child(2)', :text => "fotos"
      assert_select 'div.tab-content div#video_viewer' do
        assert_select 'div.view_container' do
          assert_select 'div.image_wrap'
          assert_select 'div.viewer_carousel div#clips'
        end
        assert_select 'div.viewer_footer div.item div.toolbar' do
          assert_select 'div.share'
          assert_select 'div.embed'
          if news.respond_to?(:videos_mpg) && news.videos_mpg.present?
            assert_select 'div.zip_download'
          end
        end
      end
    end

    assert_select 'div.downloads' do
      assert_select 'div.title span', :text => I18n.t('shared.tabs.descargas')
    end


    clear_multimedia_dir(news)
  end

  test "should show news with new design for news without multimedia" do
    news = documents(:commentable_news)
    assert news.public_tags_without_politicians.include?(tags(:viajes_oficiales))

    get :show, :id => news.id
    assert_response :success

    assert_equal 0, assigns(:videos).size, "La noticia no tiene que tener vídeos"
    assert_equal 0, assigns(:photos).size, "La noticia no tiene que tener fotos"

    assert_select 'div.photo_video_viewer div.tab-content div#video_viewer', :count => 0
    assert_select 'div.downloads', :count => 0
  end

  test "should show share links" do
    get :show, :id => documents(:commentable_news).id
    assert_select 'div.share_rss_listen' do
      assert_select 'div.share_button'
      assert_select 'div.rss_links'
    end
  end

  test "should show only public tags" do
    news = documents(:commentable_news)
    get :show, :id => news.id
    assert_response :success

    assert_select 'div.article.news div.tags ul.tag_list' do
      assert_select 'li a', /Viajes Oficiales/
      assert_select 'li a', /Agricultura, Ganadería y Forestal/
      assert_select 'li a', :text => /_lehendakaritza/, :count => 0
    end

  end

  test "should track clickthrough when clicking on a related item" do
    assert_content_is_tracked(documents(:commentable_news), documents(:one_news))
  end

  test "should track clickthrough when clicking on a search result" do
    assert_content_is_tracked(criterios(:criterio_one), documents(:one_news))
  end

  test "should track clickthrough when clicking on a tag item" do
    assert_content_is_tracked(tags(:viajes_oficiales), documents(:one_news))
  end

  test "miembro_que_modifica_noticias sees related documents rating links" do
    login_as("miembro_que_modifica_noticias")
    get :show, :id => documents(:featured_news).id
    assert_response :success
    assert_select 'ul.related' do
      assert_select 'li' do
        assert_select 'span' do
          assert_select 'a.good'
          assert_select 'a.bad'
        end
      end
    end
  end

  # Para poder hacer rating de los relacionados se require un permiso especial que no se hereda
  # del role de miembro_que_crea_noticias.
  # test "miembro_que_crea_noticias sees related documents rating links" do
  #   login_as("miembro_que_crea_noticias")

  #   assert users(:miembro_que_crea_noticias).can?("rate", "recommendations")
  #   assert documents(:featured_news).get_related_news_by_keywords.present?

  #   get :show, :id => documents(:featured_news).id
  #   assert_response :success
  #   assert_select 'ul.documents' do
  #     assert_select 'li' do
  #       assert_select 'span' do
  #         assert_select 'a.good', :count => 0
  #         assert_select 'a.bad', :count => 0
  #       end
  #     end
  #   end
  # end

  # ['admin', 'jefe_de_prensa'].each do |role|
  #   test "should show stat for #{role}" do
  #     login_as(role)
  #     get :show, :id => documents(:irekia_news).id
  #     assert_response :success

  #     assert_select 'div.admin_links a.stats'
  #   end
  # end

  roles = ["colaborador", "jefe_de_gabinete", "miembro_que_modifica_noticias", "periodista", "visitante", "comentador_oficial", "secretaria_interior", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "should not show stat for #{role}" do
      login_as(role)
      get :show, :id => documents(:irekia_news).id
      assert_response :success

      assert_select 'div.admin_links a.stats', :count => 0
    end
  end

  test "should show news with attached audio" do
    login_as("admin")
    news, pdf_at =  create_news_with_attached_pdf
    get :show, :id => news.id
    assert_response :success

    assert_select "div#tab-documents" do
      assert_select "a", pdf_at.file_file_name
    end

    assert_select 'div#tab-video' do
      assert_select 'ul', :count => 0
    end
    assert_select 'div#tab-audio' do
      assert_select 'ul', :count => 0
    end

    # clean test assets
    assert FileUtils.rm_rf File.dirname(news.attachments.first.file.path)

    news.destroy
  end

  # RSS-s
  test "should return news index rss" do
    get :index, :format => 'rss'
    assert_response :success

    assert_equal I18n.t('documents.feed_title', :name => Settings.site_name), assigns(:feed_title)
    assert_template 'news/index'
  end

  test "Area RSS should contain only news from this area" do
    get :index, :area_id => areas(:a_lehendakaritza).id, :format => 'rss'
    assert_response :success

    assert_equal "Noticias de Lehendakaritza", assigns(:feed_title)
    assert_template 'news/index'
    assert assigns(:news).collect(&:area_id).uniq == [areas(:a_lehendakaritza).id]
  end


  # XML con los datos completos de la noticia
  test "should show news in XML format" do
    doc = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)

    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, :id => doc.id
    assert_response :success
    assert_match /<document>/, @response.body
  end

  test "should show news highlighted according to criterio" do
    news = documents(:featured_news)
    criterio = criterios(:criterio_one)
    get :show, :id => news.id, :criterio_id => criterio.id, :locale => 'es'
    assert_response :success
    assert_template 'news/show'
    assert assigns(:document)
    assert assigns(:criterio)
    assert_select 'div.section_content h1' do
      assert_select 'span.highlight'
    end
  end

 if Settings.optional_modules.streaming
  test "should show with announced streaming" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now + 20.minutes, :ends_at => Time.zone.now + 2.hours)
    evt.stream_flow.update_attributes(:announced_in_irekia => true, :event_id => evt.id)
    UserActionObserver.current_user = nil

    get :index
    assert_response :success

    assert assigns(:streaming)

    if assigns(:streaming).has_next_streaming?
      assert_not_nil assigns(:streaming).announced
      assert assigns(:streaming).announced.detect {|e| e.eql?(evt)}

      assert_select 'div.streaming_block ul' do
        assert_select 'li.announced' do
          assert_select 'div.streaming_info' do
            assert_select 'span.event_title', evt.title do
              assert_select "a[href=?]", event_path(evt), evt.title
            end
          end
        end
      end
    else
      assert_select 'div.next_streaming', :count  => 0
    end
  end

  test "should show with streaming" do
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now + 20.minutes, :ends_at => Time.zone.now + 2.hours)
    evt.stream_flow.update_attributes(:show_in_irekia => true, :event_id => evt.id)

    get :index
    assert_response :success

    assert assigns(:streaming)

    if assigns(:streaming).has_next_streaming?
      assert_not_nil assigns(:streaming).live
      assert assigns(:streaming).live.detect {|e| e.eql?(evt)}

      assert_select 'div.streaming_block ul' do
        assert_select 'li.live' do
          assert_select 'div.streaming_info' do
            assert_select 'span.event_title', evt.title do
              assert_select "a[href=?]", event_path(evt), evt.title
            end
          end
        end
      end
    else
      assert_select 'div.next_streaming', :count  => 0
    end
  end

  test "should show programmed streaming" do

    next_events = Event.next4streaming

    evt = documents(:event_with_streaming)

    get :index
    assert_response :success

    assert assigns(:streaming)
    assert assigns(:streaming).has_next_streaming?
    assert_not_nil assigns(:streaming).programmed

    assert_select "div.streaming_block ul" do
      assert_select 'li.programmed' do
        assert_select "div.streaming_info" do
          assert_select "span.event_title", evt.title do
            assert_select "a[href=?]", event_path(evt)
          end
        end
      end
    end
  end
 end

  test "consejo news item should not be shown" do
    secondary_news = documents(:consejo_news)
    get :index
    all_news = assigns(:news) + [assigns(:leading_news)] + assigns(:secondary_news)

    assert_response :success
    assert assigns(:news)
    assert assigns(:leading_news) != secondary_news
    assert !assigns(:secondary_news).include?(secondary_news)
    assert !assigns(:news).include?(secondary_news)
  end

  test "featured news should be featured" do
    featured_news = documents(:featured_news)
    get :index

    assert_equal featured_news, assigns(:leading_news)
    assert_select "div.featured_news div.featured_content div.title" do
      assert_select "a[href=?]", news_path(featured_news), :text => featured_news.title
    end
  end

  # # FIXME: Funciona y deja de funcionar aleatoriamente
  # test "znews with multimedia content and with cover photo are present as second featured news" do
  #   get :index
  #   second_news = [documents(:secondary_news), documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)]
  #
  #   prepare_content_for_news_with_multimedia(documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo))
  #
  #   assert_equal 4, assigns(:secondary_news).length
  #
  #   puts assigns(:secondary_news).collect(&:title).inspect
  #
  #   second_news.each do |sn|
  #     assert assigns(:secondary_news).include?(sn)
  #   end
  #
  #   assert_select "div.secondary_news"do
  #     assert_select "div.title a", :text => second_news[0].title
  #   end
  #
  #   assert_select "div.secondary_news" do
  #     assert_select "div.title a", :text => second_news[1].title
  #   end
  #
  #   clear_multimedia_dir(documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo))
  # end


  test "should show footer banners in correct order" do
    get :index
    assert_select 'div#banners div.row-fluid' do |elements|
      assert_select 'div.item', 3
      assert_select 'div.item:nth-child(1) a', link: banners(:banner_three).url_es
      assert_select 'div.item:nth-child(2) a', link: banners(:banner_two).url_es
      assert_select 'div.item:nth-child(3) a', link: banners(:banner_one).url_es
    end
  end

  test "should not list inactive banner" do
    get :index
    assert_select 'div#banners div.row-fluid' do
      assert_select 'div.item a[href=?]', banners(:banner_no_active).url_es, count: 0
    end
  end

  test "should return area news when using the departments filter" do
    lehendakaritza = areas(:a_lehendakaritza)
    xhr :get, :index, :area_id => lehendakaritza.id
    assert assigns(:news)
    assert assigns(:news).collect(&:area_id).uniq == [lehendakaritza.id]
    assert_equal 'text/html', @response.content_type
    assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', news_url(assigns(:news).first)
  end

  test "area news index should offer link to area feed" do
    lehendakaritza = areas(:a_lehendakaritza)
    get :index, :area_id => lehendakaritza.id
    assert_select 'div.section_aside div.area_news_feed' do
      assert_select 'a[href=?]', news_index_path(:area_id => lehendakaritza.id, :format => "rss")
    end
  end

  test "news index should show area filter" do
    get :index
    assert_select 'div.filters ul li' do
      assert_select 'form[action=?]', '/es/news'
      assert_select 'select[name=?]', "area_id"
    end
  end

  test "should show link to rss feed" do
    get :index
    assert_select 'div.section_aside div.area_news_feed a[href=?]', news_index_path(:format => "rss")
  end

  test "should show link to area rss feed" do
    lehendakaritza = areas(:a_lehendakaritza)
    get :index, :area_id => lehendakaritza.id
    assert_select 'div.section_aside div.area_news_feed a[href=?]', news_index_path(:area_id => lehendakaritza.id, :format => "rss")
  end

  test "area news should show politician filter" do
    lehendakaritza = areas(:a_lehendakaritza)
    get :index, :area_id => lehendakaritza.id
    assert_select 'div.filters ul li' do
      assert_select 'form[action=?]', '/es/news'
      assert_select 'select[name=?]', "politician_id"
    end
  end


  test "should return all news when using the departments filter reset link" do
    xhr :get, :index
    assert assigns(:news)
    assert assigns(:news).collect(&:area_id).uniq.length > 1
    assert_equal 'text/html', @response.content_type
    assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', news_url(assigns(:news).first)
  end

  context "with news with politicians" do
    setup do
      @politician_lehendakaritza = users(:politician_one)
      # Assign this politician to a news
      documents(:one_news).tag_list.add(@politician_lehendakaritza.tag_name)
      documents(:one_news).save

      # Este no debería listarse al usar el filtro
      documents(:featured_news).tag_list.add(users(:politician_interior).tag_name)
      documents(:featured_news).save
    end

    should "return politician news when using cargo filter" do
      xhr :get, :index, :politician_id => @politician_lehendakaritza.id
      assert assigns(:news)
      assert assigns(:news).collect(&:politician_ids).flatten.uniq == [@politician_lehendakaritza.id]
      assert_equal 'text/html', @response.content_type
      assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', news_url(assigns(:news).first)
    end

    should "return all news when using cargo filter reset link" do
      xhr :get, :index
      assert assigns(:news)
      assert assigns(:news).collect(&:politician_ids).flatten.uniq.length > 1
      assert_equal 'text/html', @response.content_type
      assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', news_url(assigns(:news).first)
    end

    should "politician news should not show any filter" do
      get :index, :politician_id => @politician_lehendakaritza.id
      assert_select 'div.filters', :count => 0
    end

    should "should not list other politician news" do
      get :index, :politician_id => @politician_lehendakaritza.id
      assigns(:news).each do |news|
        assert news.politician_ids.include?(@politician_lehendakaritza.id)
      end
    end
  end

  context "news with external comments" do
    setup do
      @news_with_external_comments = documents(:commentable_news)
      assert @news_with_external_comments.comments.count < @news_with_external_comments.all_comments.count
    end

    should "show comments counter for other news" do
      # to ensure it is included in latest news
      assert_equal true, @news_with_external_comments.update_column(:published_at, Time.zone.now)
      get :index
      assert assigns(:other_news)
      assert_equal true, assigns(:other_news).include?(@news_with_external_comments)

      assert_select "a.comments_count[href*=\"#{news_path(@news_with_external_comments)}\"]"
      assert_select "a.comments_count[href*=\"#{news_path(@news_with_external_comments)}\"]", :text =>  @news_with_external_comments.all_comments.count
    end

    should "show comments counter for secondary news" do
      @news_with_external_comments.featured = '4B'
      assert @news_with_external_comments.save

      get :index
      assert assigns(:secondary_news)
      assert assigns(:secondary_news).detect {|n| n.id.eql?(@news_with_external_comments.id)}

      assert_select "a.comment-count[href*=\"#{news_path(@news_with_external_comments)}\"]"
      assert_select "a.comment-count[href*=\"#{news_path(@news_with_external_comments)}\"]", :text =>  @news_with_external_comments.all_comments.count
    end

    should "show comments counter for leading news" do
      @news_with_external_comments.featured = '1A'
      assert @news_with_external_comments.save

      get :index
      assert assigns(:leading_news)
      assert_equal @news_with_external_comments.id, assigns(:leading_news).id

      assert_select "a.comments_count[href*=\"#{news_path(@news_with_external_comments)}\"]"
      assert_select "a.comments_count[href*=\"#{news_path(@news_with_external_comments)}\"]", :text =>  @news_with_external_comments.all_comments.count
    end
  end

end
