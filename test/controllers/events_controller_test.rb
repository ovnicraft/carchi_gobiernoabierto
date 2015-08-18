require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  include EventsHelper
  

  def passed_events_keys
    [:event_feb_23th, :event_feb_28th, :event_march_1st, :event_august_31st, :event_apr_1st, :event_apr_5th, :event_jan_1th, :event_dic_31th_2008, :event_dic_30th_2008_to_jan_2nd_2009, :emakunde_passed_event ]
  end

  def current_events_keys
    [:current_event, :event_with_tag_one, :long_event, :published_future_event, :emakunde_current_event]
  end

  def events_hash2list(events_hash)
    all_events = []
    events_hash.keys.each do |month|
      events_hash[month].keys.each do |day|
        all_events = all_events + assigns(:events)[month][day]
      end
    end
    
    all_events
  end
  
  test "get index show calendar" do
    get :index, :locale => 'es'
    assert_response :success
    assert assigns(:events)
    
    # eli@efaber.net: Quito la comprobación de qué eventos salen en la lista porque ya se cogen sólo números.
    
    event = documents(:current_event)
    assert_select 'a.ical'
    assert_select 'table.calendar tr td.day' do
      assert_select "div.events" do
        assert_select 'a', :text => /evento/
      end
    end  
  end  

  test "get index with xhr shows the list" do
    xhr :get, :index, :locale => 'es'
    assert_response :success
    
    assert assigns(:actions)  

    # Los eventos salen con una clase que depende del día del evento y un avatar con el día del  evento      
    events = assigns(:actions)
    assert events.length > 0
    events.each do |e|
      assert_select "li#e#{e.id}" do
        assert_select "div.item_thumbnail a.date_icon" do
          assert_select "span.month", :text => I18n.localize(event_day_for_icon(e), :format => :abbr_month)
          assert_select "span.day", :text => event_day_for_icon(e).day.to_s
        end
      end
    end
  end
  
  # Para ver los eventos de un día concreto hay que pasar como argumentos el día, mes y año.
  # Si no se pasa ningún argumento, sale el primer día del mes.
  test "get list today events" do
    event = documents(:current_event)
    today = Date.today
    get :index, :locale => 'es', :day => today.day, :month => today.month, :year => today.year
    assert_response :success
    
    assert_select "h1.section_heading", :text => "#{Event.model_name.human(:count => 2).capitalize} #{I18n.l(Date.today, :format => :long)}"
    # assert_select "div.events.listing ul li.event", :count => 11
    assigns(:actions).each do |event|
      # range = event.starts_at.at_beginning_of_day..event.ends_at.end_of_day
      # assert range === Time.zone.now, "#{event.starts_at.at_beginning_of_day}..#{event.ends_at.end_of_day} does not seem to be an event for today's list"
      assert_equal true, event.starts_at.at_beginning_of_day < Time.zone.now
      assert_equal true, event.ends_at.end_of_day > Time.zone.now
    end
  end  

  test "visitors see published event with related content" do
    e = documents(:current_event)
    
    get :show, :id => e.id
    assert_response :success
    assert_template "show"
    assert assigns(:event)
    
    assert_select 'div.section_aside' do
      assert_select 'div.related_content'
    end
  end  
    
  test "visitors see published event with map" do
    UserActionObserver.current_user = users(:admin).id
    e = documents(:current_event)
    e.update_attributes(:lat => 43.273456, :lng => -2.923393 )
    assert (e.lat.present? && e.lng.present?)
    
    get :show, :id => e.id
    assert_response :success
    assert_template "show"
    assert assigns(:event)
    
    # TODO: el mapa debería estar aquí pero no se ve
    assert_select 'div.section_aside div.location div.content ul.location li div.map'
  end
  
  test "visitors do not see unpublished events" do
    # A future event. It should not be visible for normal visitors.
    e = documents(:ma_yesterday_event)
    
    get :show, :id => e.id
    assert_response :missing
    assert_template "site/notfound.html"
    assert_nil assigns(:event)
  end

  test "staff of chief do see the unpublished events" do
    e = documents(:future_event)

    login_as(:jefe_de_gabinete)
    get :show, :locale => "es", :id => e.id
    assert_response :success
    assert_template "show"
  end
  
  test "events without body_es are also listed" do
    event2check = documents(:current_event_without_body_es)
    event_date = event2check.starts_at.to_date
    get :index, :day => event_date.day, :montn => event_date.month, :year => event_date.year
    assert_response :success
    assert assigns(:events)
    assert_equal true, assigns(:events).detect {|e| e.id.eql?(event2check.id)}.present?
  end
  
  #test "should show translation missing message" do
  #  get :show, :id => documents(:untranslated_event).id, :locale => "es"
  #  assert_response :success
  #  assert !assigns(:event).translated_to?('es')
  #  assert_select 'div.traslation_missing', I18n.t('shared.traslation_missing')
  #end

  test "should show passed events of the day with class passed" do    
    # Preparamos dos eventos del mismo día, uno que ya ha pasado y otro que todavía no ha pasado.
    e = documents(:current_event)
    fe = documents(:published_future_event)
    UserActionObserver.current_user = users(:admin).id
    e.update_attribute(:ends_at, Time.zone.now)
    fe.update_attributes(:starts_at => Time.zone.now + 1.hour, :ends_at => Time.zone.now + 2.hours)
    
    assert e.passed?
    assert !fe.passed?
        
    list_date = e.starts_at.to_date
    get :index, :day => list_date.day, :month => list_date.month, :year => list_date.year
    assert_response :success
    assert_select "ul.events" do
      assert_select "li.event.passed#e#{e.id}"
      assert_select "li.event.programmed#e#{fe.id}" # TODO: Esti: esto creo que ha desaparecido (???)
    end
  end  


 if Settings.optional_modules.streaming
  test "should show event coverage info for event con streaming" do
    UserActionObserver.current_user = users(:admin).id
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    list_date = evt.starts_at.to_date
    get :index, :day => list_date.day, :month => list_date.month, :year => list_date.year
    assert_response :success
    
    assert evt.streaming_live?
    assert !evt.irekia_coverage_photo
    assert !evt.irekia_coverage_video
    assert !evt.irekia_coverage_audio  
    
    assert_template partial: 'events/_coverage_and_streaming'

    assert_select "li#e#{evt.id} div.item_content div.coverage_info div.text" do
      assert_select 'div.coverage div.info_and_link span.marked', :text => /#{I18n.t('events.irekia_coverage', :site_name => Settings.site_name, :cov_types => [I18n.t('events.streaming_for_irekia')].to_sentence).mb_chars.upcase.to_s}/
      assert_select 'div.coverage_footnote_mark', :text => /AVISO LEGAL/
    end
    
    assert_select "div.coverage_footnote"
  end

  test "should show event coverage info for event con streaming, vídeo and audio coverage" do
    UserActionObserver.current_user = users(:admin).id
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attribute(:irekia_coverage_video, true)
    evt.update_attribute(:irekia_coverage_audio, true)    
    
    list_date = evt.starts_at.to_date
    get :index, :day => list_date.day, :month => list_date.month, :year => list_date.year
    assert_response :success
    
    assert evt.streaming_live?
    assert !evt.irekia_coverage_photo
    assert evt.irekia_coverage_video
    assert evt.irekia_coverage_audio  
    
    assert_select "li#e#{evt.id} div.item_content div.coverage_info div.text div.coverage div.info_and_link span.marked", :text => "#{I18n.t('events.irekia_coverage', :site_name => Settings.site_name, :cov_types => [I18n.t('events.irekia_coverage_audio'), I18n.t('events.irekia_coverage_video'), I18n.t('events.streaming_for_irekia')].to_sentence).mb_chars.upcase.to_s}."
  end

  test "should show event coverage info for event con streaming, photo, vídeo and audio coverage" do
    UserActionObserver.current_user = users(:admin).id
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attribute(:irekia_coverage_video, true)
    evt.update_attribute(:irekia_coverage_audio, true)    
    evt.update_attribute(:irekia_coverage_photo, true)        
    
    list_date = evt.starts_at.to_date
    get :index, :day => list_date.day, :month => list_date.month, :year => list_date.year
    assert_response :success
    
    assert evt.streaming_live?
    assert evt.irekia_coverage_photo
    assert evt.irekia_coverage_video
    assert evt.irekia_coverage_audio  
    
    assert_select "li#e#{evt.id} div.item_content  div.coverage_info div.text div.coverage div.info_and_link span.marked", :text => /#{I18n.t('events.irekia_coverage', :site_name => Settings.site_name, :cov_types => [I18n.t('events.irekia_coverage_audio'), I18n.t('events.irekia_coverage_video'), I18n.t('events.irekia_coverage_photo'), I18n.t('events.streaming_for_irekia')].to_sentence).mb_chars.upcase.to_s}/
  end

  test "should not show event coverage info" do
    UserActionObserver.current_user = users(:admin).id
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attribute(:streaming_for, "")
    assert !evt.streaming_for_irekia?
    
    list_date = evt.starts_at.to_date
    get :index, :day => list_date.day, :month => list_date.month, :year => list_date.year
    assert_response :success

    assert_select "li#e#{evt.id} div.item_content" do
      assert_select 'div.coverage_info', :count => 0
    end
    
  end
  test "should show coverage info for event without streaming" do
    # Evento con cobertura de fotos y vídeo, sin streaming.
    UserActionObserver.current_user = users(:admin)
    evt = documents(:emakunde_passed_event)
    evt.update_attributes(:irekia_coverage_photo => true, :irekia_coverage_video => true)
    UserActionObserver.current_user = nil
    assert evt.streaming_for.blank?
    assert evt.irekia_coverage_photo?
    
    get :show, :id => evt.id
    assert_response :success
    
    assert_select 'div.coverage_info div.text', :text => /VÍDEO Y FOTOS/
  end

  test "should show coverage info for programmed event without streaming" do
    # Evento con cobertura de fotos y vídeo, sin streaming.
    UserActionObserver.current_user = users(:admin)
    evt = documents(:current_event)
    assert evt.update_attributes(:starts_at => Time.zone.now + 1.hour, :ends_at => Time.zone.now + 2.hour, :irekia_coverage => true, :irekia_coverage_photo => true, :irekia_coverage_video => true)
    UserActionObserver.current_user = nil
    assert evt.streaming_for.blank?
    assert evt.irekia_coverage?
    assert evt.irekia_coverage_photo?
    assert_equal :empty, evt.streaming_status.to_sym
    
    get :show, :id => evt.id
    assert_response :success

    assert assigns(:event).streaming_for.blank?
    assert assigns(:event).irekia_coverage?
    assert assigns(:event).irekia_coverage_photo?
    assert_equal :empty, assigns(:event).streaming_status.to_sym
    
    
    assert_select 'div.coverage_info' do
      assert_select 'div.text', :html => /VÍDEO Y FOTOS/
    end
    assert_select 'span.streaming_status', :count => 0
  end

  test "should show empty player on the event page if event is programmed and not streamed nor announced" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.stream_flow.update_attributes(:show_in_irekia => false, :event_id => evt.id)
    UserActionObserver.current_user = nil
    assert !evt.on_air?
    
    get :show, :id => evt.id
    assert_response :success

    # Ventana azul con texto "evento programado"
    assert_select 'div.coverage_info' do
      assert_select 'div.text', :text => /PRÓXIMA EMISIÓN/
    end
    assert_select 'div.streaming_video' do
      assert_select 'div.format169.video' do
        assert_select 'div.player', :count => 0
        assert_select 'div.announcement', :count => 0        
        assert_select 'div.empty_player'
      end
    end
  end

  test "should show announcement on the event page while event streaming is announced" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now + 20.minutes, :ends_at => Time.zone.now + 2.hours)
    evt.stream_flow.update_attributes(:announced_in_irekia => true, :event_id => evt.id)
    UserActionObserver.current_user = nil
    
    get :show, :id => evt.id
    assert_response :success

    assert_select 'div.coverage_info' do
      assert_select 'div.text div', :text => I18n.t('events.announced_streaming').mb_chars.upcase.to_s
    end
    assert_select 'div.streaming_video' do
      assert_select 'div.format169.video' do
        assert_select 'div.announcement'
      end
    end
  end
  
  test "should show streaming on the event page while event is streamed live" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now + 20.minutes, :ends_at => Time.zone.now + 2.hours)
    evt.stream_flow.update_attributes(:show_in_irekia => true, :event_id => evt.id)
    UserActionObserver.current_user = nil
    
    get :show, :id => evt.id
    assert_response :success
    
    assert_select 'div.coverage_info' do
      assert_select 'div.text', :text => /CONEXIÓN EN DIRECTO/
    end
    assert_select 'div.streaming_video' do
      assert_select 'div.format169.video' do
        assert_select 'a.player'
      end
    end
  end

  test "should show coverage info on the event page when event has finished" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now - 1.day, :ends_at => Time.zone.now - 1.day + 2.hours)
    evt.stream_flow.update_attributes(:show_in_irekia => false, :event_id => evt.id)
    UserActionObserver.current_user = nil
    
    get :show, :id => evt.id
    assert_response :success
    
    assert_select 'div.coverage_info', /#{I18n.t('events.irekia_covered', :site_name => Settings.site_name, :cov_types => I18n.t('events.streaming_for_irekia')).mb_chars.upcase.to_s}/
    assert_select 'div.streaming_video', :count => 0
  end

  
  test "should not show straming on the event page if event is not streamed live but there is streaming form the same room" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now + 20.minutes, :ends_at => Time.zone.now + 2.hours)
    evt.stream_flow.update_attributes(:show_in_irekia => true, :event_id => evt.id)
    
    evt2 = documents(:event_with_streaming_without_alerts)
    evt2.update_attributes(:stream_flow_id => evt.stream_flow_id)
    UserActionObserver.current_user = nil
    
    get :show, :id => evt2.id
    assert_response :success

    assert_select 'div.coverage_info'
    assert_select 'div.streaming_video' do
      assert_select 'a.player', :count => 0
      assert_select 'div.empty_player'
    end
  end
  
  # XML
  test "should show published event without streaming in XML format" do
    e = documents(:current_event)
    
    # Pasando :format => :xml da error 406, por esto pongo a mano @request.env['HTTP_ACCEPT']
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    
    get :show, :id => e.id
    assert_response :success
    assert_template "show"
    assert assigns(:event)
    
    assert_match /<estado>sin/, @response.body
  end

  test "should show event with programmed streaming in XML format" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now + 20.minutes, :ends_at => Time.zone.now + 2.hours)
    UserActionObserver.current_user = nil
    
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, :id => evt.id
    assert_response :success
    assert_match /<estado>previsto/, @response.body
  end  
    
    
  test "should show event with streaming while event is streamed live in XML format" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now + 20.minutes, :ends_at => Time.zone.now + 2.hours)
    evt.stream_flow.update_attributes(:show_in_irekia => true, :event_id => evt.id)
    UserActionObserver.current_user = nil
    
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, :id => evt.id
    assert_response :success
    assert_match /<estado>emitiendo/, @response.body
  end  
 end

  test "should get public events feed" do
    get :myfeed, :format => 'ics'
    assert_response :success
    assert_template 'myfeed'
    assert assigns(:events)
  end
  test "should show event page with related news link" do
    get :show, :id => documents(:emakunde_passed_event).id
    assert_response :success
    
    assert_select 'div.more_info' do
      assert_select 'span.tag_links' do
        assert_select 'a[href=?]', news_path(documents(:news_with_event))
        assert_select 'a', documents(:news_with_event).title
      end
    end
  end
  
  #
  # El aviso "Sólo médios gráficos" sale solamente en AM. 
  # Nos aseguramos que no sale en irekia.
  #
  test "should show event only for photographers without journalists notice" do
    get :show, :id => documents(:event_with_tag_one).id
    assert_response :success
    
    assert documents(:event_with_tag_one).only_photographers?
    
    assert_select 'div.journalists_notice', :count => 0
  end


  test "should not show private event page" do
    get :show, :id => documents(:ma_yesterday_event).id
    #assert_response :success
    assert_response :missing
    assert_template 'site/notfound.html'
  end

  test "should show event page without related news link to agencia" do
    event = documents(:passed_event)
    news = documents(:agencia_news)
    assert_equal [news], event.news
    
    assert news.is_private?
    assert !news.published?

    assert event.is_public?
    
    get :show, :id => event.id
    assert_response :success
    
    assert_select 'div.more_info', :count => 0
  end

  test "should show event in ics format" do
    get :show, :id => documents(:current_event), :format => "ics"
    assert_response :success
    assert_template "show"
  end

  
  test "should track clickthrough when clicking on a search result" do
    assert_content_is_tracked(criterios(:criterio_one), documents(:passed_event))
  end
  
  test "should track clickthrough when clicking on a tag item" do
    assert_content_is_tracked(tags(:viajes_oficiales), documents(:passed_event))
  end
  
  # 2DO  
  # ['admin', 'jefe_de_prensa'].each do |role|
  #   test "should show stat for #{role}" do
  #     login_as(role)
  #     get :show, :id => documents(:old_event_with_streaming_and_sent_alert_and_show_in_irekia).id
  #     assert_response :success
  #     
  #     assert_select 'ul.stats_data'
  #   end
  # end
  # 
  # ["colaborador", "jefe_de_gabinete", "editor", "miembro_que_modifica_noticias", "periodista", "visitante", "comentador_oficial", "secretaria_interior", "operador_de_streaming", "room_manager"].each do |role|
  #   test "should show stat for #{role}" do
  #     login_as(role)
  #     get :show, :id => documents(:old_event_with_streaming_and_sent_alert_and_show_in_irekia).id
  #     assert_response :success
  #     
  #     assert_select 'ul.stats_data', :count => 0
  #   end
  # end



  test "should show event with related news in XML format" do
    evt = documents(:emakunde_passed_event)
    assert evt.passed?
    
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, :id => evt.id
    assert_response :success
    assert_match /<estado>noticia/, @response.body    
  end
  
  test "should return area events when using the departments filter" do
    lehendakaritza = areas(:a_lehendakaritza)
    xhr :get, :index, :area_id => lehendakaritza.id
    assert assigns(:actions)
    assert assigns(:actions).collect(&:area_id).uniq == [lehendakaritza.id]
    assert_equal 'text/html', @response.content_type
    assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', event_url(assigns(:actions).first)
  end
  
  test "should return all events when using the departments filter reset link" do
    xhr :get, :index
    assert assigns(:actions)
    assert assigns(:actions).collect(&:area_id).uniq.length > 1
    assert_equal 'text/html', @response.content_type
    assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', event_url(assigns(:actions).first)
  end
  
  test "events index should show area filter" do
    get :index
    assert_select 'div.filters ul li' do
      assert_select 'form[action=?]', '/es/events'
      assert_select 'select[name=?]', "area_id"
    end
  end

  test "area events should show politician filterxx" do
    lehendakaritza = areas(:a_lehendakaritza)
    get :index, :area_id => lehendakaritza.id
    assert_select 'div.filters ul li' do
      assert_select 'form[action=?]', '/es/events'
      assert_select 'select[name=?]', "politician_id"
    end
  end
  
  context "with events with politicians" do
    setup do 
      @politician_lehendakaritza = users(:politician_one)
      
      # Assign this politician to a event
      current_event = documents(:current_event)
      # Para que el tst funcione desde el rake hay que asignar el tagging en vez del tag.
      # current_event.tag_list.add(@politician_lehendakaritza.tag_name)
      # current_event.save
      current_event.taggings.create(:tag => @politician_lehendakaritza.tag, :context => 'tags')

      # Este no debería  listarse al usar el filtro
      # event_with_tag_one también es de lehendakaritza así que al quitar el filtro sí debe aparecer
      event_with_tag_one = documents(:event_with_tag_one)
      # Para que el tst funcione desde el rake hay que asignar el tagging en vez del tag.      
      # event_with_tag_one.tag_list.add(users(:politician_interior).tag_name)
      # event_with_tag_one.save
      event_with_tag_one.taggings.create(:tag => users(:politician_interior).tag, :context => 'tags')
    end

    should "not list events for politician without agenda" do
      @politician_lehendakaritza.update_attribute(:politician_has_agenda, false)
      assert !@politician_lehendakaritza.politician_has_agenda?
      get :index, :politician_id => @politician_lehendakaritza.id
      assert_equal I18n.t('politicians.no_tiene_agenda_publica'), flash[:notice]
      assert_redirected_to politician_path(:id => @politician_lehendakaritza, :anchor => 'top')
    end
    
    context "who has public agenda" do
      setup do 
        assert_equal true, @politician_lehendakaritza.events.present?
      end
      
      should "return politician events when using cargo filter" do
        xhr :get, :index, :politician_id => @politician_lehendakaritza.id
        assert assigns(:actions)
        assert assigns(:actions).collect(&:politician_ids).flatten.uniq 
        assert_equal 'text/html', @response.content_type
        assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', event_url(assigns(:actions).first)
      end
    
      context "cargo filter in area page" do
        setup do
          @lehendakaritza = areas(:a_lehendakaritza)
          @lehendakaritza.users << users(:politician_one)
        end

        should "return all news when using cargo filter reset link" do
          xhr :get, :index, :area_id => areas(:a_lehendakaritza).id
          assert assigns(:actions)
          assert assigns(:actions).collect(&:politician_ids).flatten.uniq.length > 1
          assert_equal 'text/html', @response.content_type
          assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', event_url(assigns(:actions).first)
        end
      
        should "offer only politicians with agenda in filter select" do
          assert @politician_lehendakaritza.politician_has_agenda?
          assert !users(:politician_interior).politician_has_agenda?
          get :index, :area_id => areas(:a_lehendakaritza).id
          assert_select 'form#area_filter' do
            assert_select 'select[name=?]', 'politician_id' do
              assert_select 'option[value=?]', @politician_lehendakaritza.id
              assert_select 'option[value=?]', users(:politician_interior).id, :count => 0
            end
          end
        end
      end
      
      should "politician events should not show any filter" do
        get :index, :politician_id => @politician_lehendakaritza.id
        assert_select 'div.filters', :count => 0
      end

      should "should not list other politician events" do
        get :index, :politician_id => @politician_lehendakaritza.id
        assigns(:actions).each do |news|
          assert news.politician_ids.include?(@politician_lehendakaritza.id)
        end
        assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title a[href=?]', event_url(assigns(:actions).first)
      end
    end
  end

end
