require 'test_helper'

class Sadmin::EventsControllerTest < ActionController::TestCase

  test "redirect if not logged" do
    get :index
    assert_not_authorized
  end

  ["admin", "jefe_de_prensa", "jefe_de_gabinete", "miembro_que_modifica_noticias", "comentador_oficial"].each do |role|
    test "show index if logged as #{role}" do
      login_as(role)
      get :index
      assert_response :success
      assert_template "index"

      assert_select "div.calendar_legend" do
        assert_select "ul" do
          assert_select "li:nth-child(1)", "Leyenda:"
          assert_select "li:nth-child(2)", "Uso interno del Gobierno"
          assert_select "li:nth-child(3)", "Publicado en irekia"
          assert_select "li:nth-child(4)", "Cubre #{Settings.site_name}"
        end
      end

      assert_select "ul.edit_links li a", "Suscripción"
    end
  end

  test "show index if logged as secretaria_interior" do
    login_as("secretaria_interior")
    get :index
    assert_response :success
    assert_template "index"

    assert_select "div.calendar_legend" do
      assert_select "ul" do
        assert_select "li:nth-child(1)", "Leyenda:"
        assert_select "li:nth-child(2)", "Uso interno del Gobierno"
        assert_select "li:nth-child(3)", "Publicado en irekia"
        assert_select "li:nth-child(4)", "Cubre #{Settings.site_name}"
      end
    end

    assert_select "ul.edit_links li a", "Suscripción"
  end


  users = ["periodista", "visitante", "colaborador", "room_manager"]
  users << "operador_de_streaming" if Settings.optional_modules.streaming
  users.each do |role|
    test "redirect if logged as #{role}" do
      login_as(role)
      get :index
      assert_not_authorized
    end
  end

  test "index for secretaria interior" do
    login_as(:secretaria_interior)
    get :index
    assert_response :success

    # Department members have only the 'Agenda' option in the menu bar.
    assert_select "div.menu_admin" do
      assert_select "ul" do
        ["Agenda"].each_with_index do |text, n|
         assert_select "li:nth-child(#{n+1})" do
           assert_select 'a', text
         end
       end
       assert_select "ul li", :count => 1
      end
    end



    month = Time.zone.now.month
    today = Time.zone.now.day
    last_day= Time.zone.now.at_end_of_month.day
    assert assigns(:events)

    # Department members can see all the events of the shared agenda.
    assert assigns(:events)[month][today].detect {|e| e.is_a?(Event) && !e.organization_id.eql?(organizations(:interior).id)}

    # Department member do see the public events that correspond to their department.
    assert assigns(:events)[month][last_day].detect {|e| e.is_a?(Event) && e.id.eql?(documents(:interior_public_event).id)}

  end

  test "menu for comentador oficial" do
    login_as(:comentador_oficial)
    get :index
    assert_response :success

    assert_select "div.menu_admin" do
      assert_select "ul" do
        modules = ["Agenda"]
        modules << "Peticiones" if Settings.optional_modules.proposals
        modules << "Comentarios"
        modules.each_with_index do |text, n|
         assert_select "li:nth-child(#{n+1})" do
           assert_select 'a', text
         end
       end
       assert_select "ul li", :count => modules.length
      end
    end
  end

  test "weekly view should show event starting in one week and ending in another" do
    login_as("admin")
    date = Date.today
    get :week, :day => date.day, :month => date.month, :year => date.year
    assert assigns(:events).detect {|e| e.id.eql?(documents(:event_with_duration_of_more_than_one_week).id)}, "Event event_with_duration_of_more_than_one_week should be listed"
  end

  test "weekly view should start with the first day of week" do
    login_as("admin")
    date = Time.zone.now.to_date
    first_day = Time.zone.now.at_beginning_of_week.to_date

    get :week, :day => date.day, :month => date.month, :year => date.year
    assert_response :success
    assert assigns(:events)

    week_events_dates = assigns(:events).map {|e| e.starts_at.to_date if e.starts_at.to_date >= first_day}.compact.uniq.sort

    days = css_select('div.one_day')
    assert_select days[0], 'h3', :text => I18n.localize(week_events_dates.first, :format => :long).strip
    assert_select 'div.long_events' do
      assert_select 'div.one_day h3', :text => I18n.localize(documents(:event_that_starts_the_week_before_now_with_duration_of_more_than_one_week).starts_at.to_date, :format => :long).strip
    end

  end

  test "weekly view should show event starting the last day of the week" do
    login_as("admin")
    date = Date.today
    get :week, :day => date.day, :month => date.month, :year => date.year

    assert assigns(:events).detect {|e| e.id.eql?(documents(:event_with_duration_of_more_than_one_week).id)}, "Event event_with_duration_of_more_than_one_week should be listed"
    assert assigns(:events).detect {|e| e.id.eql?(documents(:sunday_event).id)}, "Sunday event should be listed"
  end


  test "calendar action renders index.html" do
    login_as(:jefe_de_gabinete)
    post :calendar
    assert_response :success
    assert_template 'sadmin/events/index'
  end

  test "jefe_de_gabinete sees edit links" do
    login_as(:jefe_de_gabinete)
    get :index
    assert_response :success

    assert_select "div.create_links ul.edit_links", :count => 1
    assert_select "div.create_links ul.edit_links li", :count => 1
  end

  test "secreatria sees create event link" do
    login_as(:secretaria)
    get :index
    assert_response :success

    assert_select "div.create_links ul.edit_links", :count => 1
  end

  test "jefe_de_gabinite can see the agenda" do
    login_as(:jefe_de_gabinete)
    month = Time.zone.now.month
    get :calendar, :month => month, :year => Time.zone.now.year
    assert_response :success
    assert assigns(:events)

    today = Time.zone.now.day

    assert assigns(:events)[month][today].detect {|e| e.is_a?(Event) && e.id.eql?(documents(:current_event).id)}, 'Current event shoud be in the events list.'

    assert_select "h1.title", "Agenda Gobierno compartida"
  end

  test "secretaria can see the calendar" do
    login_as(:secretaria)

    month = Time.zone.now.month
    today = Time.zone.now.day

    get :calendar, :month => month, :year => Time.zone.now.year
    assert_response :success
    assert assigns(:events)

    assert assigns(:events)[month][today].detect {|e| e.is_a?(Event) && e.id.eql?(documents(:current_event).id)}, 'Current event shoud be in the events list.'
    assert assigns(:events)[month][1.day.from_now.day].detect {|e| e.is_a?(Event) && e.id.eql?(documents(:private_event).id)}, 'Private event should be in the events list.'

    assert_select "h1.title", "Agenda Gobierno compartida"

  end


  test "department member does not have permission for creating events XX" do
    login_as(:secretaria_interior)

    month = Time.zone.now.month
    today = Time.zone.now.day


    get :calendar, :month => month, :year => Time.zone.now.year
    assert_response :success

    assert_select 'div.create_links ul.edit_links', :count => 0
  end



  test "should show month calendar with events last week in previous month" do
    login_as(:secretaria)
    # Calendario del mes siguiente
    date = (Time.zone.now.at_end_of_month + 1.day)
    post :calendar, :year => date.year, :month => date.month
    assert_response :success
    assert_template 'sadmin/events/index'

    # Evento de la agenda privada del último día del mes.
    # Tiene que salir al principio del calendario del mes siguiente.
    last_day_evt = documents(:ee_last_day_of_month)

    assert assigns(:events)[last_day_evt.month]
    assert_not_nil assigns(:events)[last_day_evt.month][last_day_evt.day].detect {|e| e.id.eql?(last_day_evt.id)}

    if date.to_date.at_beginning_of_week.eql?(date.to_date)
      # Si el mes empieza el lunes, no hay que mostrar los eventos de los últimos días del mes anterior.
      # aunque éstos sí estén en assigns(:events) porque allí siempre cogemos una semana por delante y
      # otra por detrás del mes que consultamos
      assert_select "td#d#{last_day_evt.day}_#{last_day_evt.month}", :count => 0

    else
      # Si el mes no empieza el lunes, hay que mostrar los eventos de los últimos días del mes anterior.
      assert_select 'table.calendar tbody tr' do |trs|
        assert_select trs.first, "td.otherMonth" do |tds|
          assert_select tds.last, 'div.day_number' do
            assert_select 'a.day_number', :text => last_day_evt.day
          end

          # 3 = Sadmin::EventsHelper.num_events_in_cell
          # Se cogen events[0..Sadmin::EventsHelper.num_events_in_cell], en total 4
          num_events_shown_in_cell = 4
          # Si hay más de tres eventos, el last_day_evt no sale en el calendario.
          # Esto pasa cuando se ejecuta el test a final del mes y entonces el último día
          # coinciden varios de los eventos largos que se solapan con el last_day_evt.
          if assigns(:events)[last_day_evt.month][last_day_evt.day].size <= num_events_shown_in_cell
            assert_select tds.last, "div.irekia_event"
          else
            # estamos en la última casilla del mes anterior 

            assert_select tds.last, "div.more_events_link"
          end
        end
      end
    end
  end


  test "jefe_de_gabinete see agenda events list" do
    login_as(:jefe_de_gabinete)
    now = Time.zone.now
    month = now.month
    get :list, :month => month, :year => now.year, :day => now.day
    assert_response :success
    assert assigns(:documents)

    assert assigns(:documents).detect {|e| e.is_a?(Event) && e.id.eql?(documents(:current_event).id)}, 'Current event shoud be in the events list.'

  end

  test "secretaria sees agenda events " do
    login_as(:secretaria)
    now = Time.zone.now
    month = now.month
    get :list, :month => month, :year => now.year, :day => now.day
    assert_response :success
    assert assigns(:documents)

    assert assigns(:documents).detect {|e| e.is_a?(Event) && e.id.eql?(documents(:current_event).id)}, 'Current event shoud be in the events list.'
  end

  test "secretaria sees private events in the week view" do
    login_as(:secretaria)
    now = Time.zone.now
    month = now.month
    get :week, :month => month, :year => now.year, :day => now.day
    assert_response :success
    assert assigns(:events)

    assert assigns(:events).detect {|e| e.is_a?(Event) && e.id.eql?(documents(:current_event).id)}, 'Current event shoud be in the events list.'
    assert assigns(:events).detect {|e| e.is_a?(Event) && e.id.eql?(documents(:private_event).id)}, 'Private event "private_event" should be in the events list.'
  end

  test "secretaria interior sees all shared events in the week view" do
    login_as(:secretaria_interior)
    now = documents(:interior_public_event).starts_at
    month = now.month
    get :week, :month => month, :year => now.year, :day => now.day
    assert_response :success
    assert assigns(:events)

    assert assigns(:events).detect {|e| e.is_a?(Event) && !e.department.id.eql?(organizations(:interior).id)}, 'Events for other depts shoud not be in the events list.'
    assert assigns(:events).detect {|e| e.is_a?(Event) && e.id.eql?(documents(:interior_public_event).id)}, 'Special event should be in the events list.'

  end



  test "list should contain only interior events and shared events" do
    login_as(:secretaria_interior)

    now = documents(:interior_public_event).starts_at
    month = now.month
    get :list, :month => month, :year => now.year, :day => now.day
    assert_response :success
    assert assigns(:documents)

    assigns(:documents).map {|e| e unless e.department.id.eql?(organizations(:interior).id)}.compact do |evt|
      assert evt.is_a?(Event)
    end

  end

  test "list for a day without events should be empty if user can not edit events" do
    login_as(:secretaria_interior)

    now = Time.zone.now.at_beginning_of_month
    month = now.month
    get :list, :month => month, :year => now.year, :day => now.day
    assert_response :success
    assert assigns(:documents)

  end


  test "list for a day without events should redirect is user can_edit events" do
    login_as(:secretaria)

    now = Time.zone.now + 3.months
    month = now.month
    get :list, :month => month, :year => now.year, :day => now.day
    assert_response :redirect
  end

  ["admin", "jefe_de_prensa", "jefe_de_gabinete", "secretaria_interior", "miembro_que_modifica_noticias", "comentador_oficial"].each do |role|
    test "myfeed is available for #{role}" do
      user = users(role.to_sym)
      get :myfeed, :u => user.id, :p => user.crypted_password, :format => 'ics'
      assert_response :success
      assert assigns(:events)
    end
  end

  test "myfeed for jefe_de_gabinete includes agenda events" do
    user = users(:jefe_de_gabinete)
    get :myfeed, :u => user.id, :p => user.crypted_password, :format => 'ics'
    assert_response :success
    assert assigns(:events)

    assert assigns(:events).detect {|e| e.is_a?(Event) && e.id.eql?(documents(:current_event).id)}, 'Current event shoud be in the events list.'
  end

  test "myfeed for secretaria includes agenda events" do
    user = users(:secretaria)
    get :myfeed, :u => user.id, :p => user.crypted_password, :format => 'ics'
    assert_response :success
    assert assigns(:events)

    assert assigns(:events).detect {|e| e.is_a?(Event) && e.id.eql?(documents(:current_event).id)}, 'Current event shoud be in the events list.'
  end

  test "get new event form" do
    login_as(:jefe_de_gabinete)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    get :new
    assert assigns(:event)
    assert assigns(:event).is_private?
    assert !assigns(:event).has_journalists
    assert !assigns(:event).has_photographers

    # NUEVO: comprobamos todos los campos del formulario
    ["politicians_tag_list", "speaker", "title_es", "place", "city", "location_for_gmaps", "all_journalists", "only_photographers"].each do |name|
      assert_select "input#event_#{name}"
    end

    assert_select 'div.is_private_radio_options', :count => 1 # siempre está porque dentro están las opciones de uso privado y agenda compartida además de las agendas privadas
    assert_select "input#event_is_private__1" # uso privado
    assert_select "input#event_is_private_0"  # evento público
    assert_select "input#event_alertable" # si se quiere alertar sobre este evento o no
  end

  test "should create new private event" do
    login_as(:jefe_de_gabinete)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    assert_difference('Event.count') do
      post :create, :event => {"starts_at(1i)" => starts_at.year.to_s,
                               "starts_at(2i)" => starts_at.month.to_s,
                               "starts_at(3i)" => starts_at.day.to_s,
                               "ends_at(1i)" => ends_at.year.to_s,
                               "ends_at(2i)" => ends_at.month.to_s,
                               "ends_at(3i)" => ends_at.day.to_s,
                               "title_es"   => 'El tema del evento',
                               "organization_id" => organizations(:lehendakaritza).id,
                               "is_private" => "1", # así indicamos que el evento es privado
                               "alertable" => false
                               }
    end
    assert assigns(:event).is_private?
    assert !assigns(:event).published?
    assert_redirected_to sadmin_event_url(:id => assigns(:event).id, :fresh => 1)
  end

  test "should create new public event" do
    login_as(:jefe_de_gabinete)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    assert_difference('Event.count') do
      post :create, :event => {"starts_at(1i)" => starts_at.year.to_s,
                               "starts_at(2i)" => starts_at.month.to_s,
                               "starts_at(3i)" => starts_at.day.to_s,
                               "ends_at(1i)" => ends_at.year.to_s,
                               "ends_at(2i)" => ends_at.month.to_s,
                               "ends_at(3i)" => ends_at.day.to_s,
                               "title_es"   => 'El tema del evento',
                               "organization_id" => organizations(:lehendakaritza).id,
                               "is_private" => '0', # así indicamos que el evento es público
                               "alertable" => true
                              }
    end
    assert assigns(:event).is_public?
    assert assigns(:event).published?

    assert !assigns(:event).all_journalists?
    assert !assigns(:event).only_photographers?
    assert !assigns(:event).has_photographers?
    assert !assigns(:event).has_journalists

    assert_redirected_to sadmin_event_url(:id => assigns(:event).id, :fresh => 1)
  end



  test "should create new event for an entity which is not department" do
    login_as(:jefe_de_gabinete)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    assert_difference('Event.count') do
      post :create, :event => {"starts_at(1i)" => starts_at.year.to_s,
                               "starts_at(2i)" => starts_at.month.to_s,
                               "starts_at(3i)" => starts_at.day.to_s,
                               "ends_at(1i)" => ends_at.year.to_s,
                               "ends_at(2i)" => ends_at.month.to_s,
                               "ends_at(3i)" => ends_at.day.to_s,
                               "title_es"   => 'El tema del evento',
                               "organization_id" => organizations(:emakunde).id,
                               "alertable" => false}

    end
    assert assigns(:event).is_private?
    assert_redirected_to sadmin_event_url(:id => assigns(:event).id, :fresh => 1)
  end


  test "should not create new event if user can not edit events" do
    login_as(:secretaria_interior)
    assert !users(:secretaria_interior).can_edit?('events')

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    assert_no_difference('Event.count') do
      post :create, :event => {"starts_at(1i)"   => starts_at.year.to_s,
                               "starts_at(2i)"   => starts_at.month.to_s,
                               "starts_at(3i)"   => starts_at.day.to_s,
                               "ends_at(1i)"     => ends_at.year.to_s,
                               "ends_at(2i)"     => ends_at.month.to_s,
                               "ends_at(3i)"     => ends_at.day.to_s,
                               "title_es"        => 'El tema del evento',
                               "body_es"         => 'El texto del evento',
                               "organization_id" => organizations(:lehendakaritza).id,
                               "only_photographers" => 0,
                               "alertable" => true}
    end
    assert_not_authorized
  end

  test "should create new event if user can create private events and events and is_private is null" do
    login_as(:secretaria)
    assert users(:secretaria).can_create?('events')

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    assert_difference('Event.count') do
      post :create, :event => {"starts_at(1i)"   => starts_at.year.to_s,
                               "starts_at(2i)"   => starts_at.month.to_s,
                               "starts_at(3i)"   => starts_at.day.to_s,
                               "ends_at(1i)"     => ends_at.year.to_s,
                               "ends_at(2i)"     => ends_at.month.to_s,
                               "ends_at(3i)"     => ends_at.day.to_s,
                               "title_es"        => 'El tema del evento',
                               "body_es"         => 'El texto del evento',
                               "organization_id" => organizations(:gobierno_vasco).id,
                               "is_private"     => nil}
      assert assigns(:event).errors.blank?
    end
    assert assigns(:event)
    assert assigns(:event).is_a?(Event)
    assert assigns(:event).is_private?
  end


  test "should create new public event if user can create private events and events and private is 0" do
    login_as(:secretaria)
    assert users(:secretaria).can_create?('events')

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    assert_difference('Event.count') do
      post :create, :event => {"starts_at(1i)"   => starts_at.year.to_s,
                               "starts_at(2i)"   => starts_at.month.to_s,
                               "starts_at(3i)"   => starts_at.day.to_s,
                               "ends_at(1i)"     => ends_at.year.to_s,
                               "ends_at(2i)"     => ends_at.month.to_s,
                               "ends_at(3i)"     => ends_at.day.to_s,
                               "title_es"        => 'El tema del evento',
                               "body_es"         => 'El texto del evento',
                               "organization_id" => organizations(:gobierno_vasco).id,
                               "is_private"     => "0",
                               "alertable" => true
                               }
      assert assigns(:event).errors.blank?
    end
    assert assigns(:event)
    assert assigns(:event).is_a?(Event)
    assert assigns(:event).is_public?
  end


  test "should show event" do
    login_as(:jefe_de_gabinete)

    get :show, :id => documents(:current_event)
    assert_response :success
    assert assigns(:event)

    assert_select "div.create_links", :count => 0

    # Evento de Irekia -> hay tres opciones: exportatr a ical, preview
    assert_select "div.event_edit_links" do
      assert_select "ul.edit_links" do |elements|
        assert_select elements.first, "li", 2
        # Evento de Irekia -> hay dos opciones: exportatr a ical, preview
        assert_select elements.first, "li", 2
        # y aparte eliminar
        assert_select elements.last, "li", 1
      end
    end

    assert_select 'div.create_update_info'

    assert_select 'table.admin' do
      assert_select 'tr:nth-child(1)' do
        assert_select 'th', /Visibilidad/
        assert_select 'td', /Sí/
        # assert_select 'td', /No, no se muestra en Agencia/
      end
    end

  end

 if Settings.optional_modules.streaming
  test "should show event with streaming" do
    login_as(:jefe_de_gabinete)

    get :show, :id => documents(:event_with_streaming)
    assert_response :success
    assert assigns(:event)

    assert_select "div.create_links", :count => 0

    assert_select "div.event_edit_links" do
      assert_select "ul.edit_links" do |elements|
        # Evento de Irekia -> hay tres opciones: exportatr a ical, preview
        assert_select elements.first, "li", 2
        # y eliminar aparte
        assert_select elements.last, "li", 1
      end
      assert assigns(:event).streaming_for_irekia?
      assert_select 'div.coverage', :text => I18n.t('events.irekia_coverage', :site_name => Settings.site_name, :cov_types => I18n.t('events.streaming_for_irekia')).mb_chars.upcase.to_s + '.'
    end

    assert_select 'div.create_update_info'

    assert_select 'table.admin' do
      assert_select 'tr:nth-child(1)' do
        assert_select 'th', /Visibilidad/
        assert_select 'td', /Sí/
        # assert_select 'td', /Sí, se muestra en Agencia/
      end
    end

  end
 end

  test "should show fresh event" do
    login_as(:jefe_de_gabinete)

    get :show, :id => documents(:current_event), :fresh => 1
    assert_response :success
    assert assigns(:event)

    assert_select "div.create_links", :count => 1
    assert_select 'div.create_update_info'

    assert_select 'div.related_news' do
      assert_select 'ul.edit_links' do
        assert_select 'li a', 'Crear borrador de noticia'
        assert_select 'li span', 'Buscar noticia'
      end
    end

  end

  test "should show private event to jefe_de_gabinete" do
    login_as(:jefe_de_gabinete)

    get :show, :id => documents(:private_event)
    assert_response :success
    assert assigns(:event)

    assert_select "div.create_links", :count => 0

    # Evento privado -> hay una opción: exportatr a ical
    assert_select "div.event_edit_links" do
      assert_select "ul.edit_links" do |elements|
        # Evento de Irekia -> hay tres opciones: exportatr a ical
        assert_select "li", count: 3
      end
    end

    assert_select 'div.create_update_info'

    assert_select 'div.related_news' do
      assert_select 'ul.edit_links', :count => 1
    end

  end

  test "should show private event to secretaria" do
    login_as(:secretaria)

    get :show, :id => documents(:private_event)
    assert_response :success
    assert assigns(:event)

    assert_select "div.create_links", :count => 0

    # Evento privado -> hay dos opciones: exportatr a ical y eliminar
    assert_select "div.event_edit_links" do
      assert_select "ul.edit_links" do
        assert_select "li", :count => 3
      end
    end
  end

  test "should show event with related news" do
    login_as(:jefe_de_prensa)

    get :show, :id => documents(:emakunde_passed_event)
    assert_response :success
    assert assigns(:event)

    assert_select 'div.related_news' do
      assert_select 'div.news_title', /#{assigns(:event).news.first.title}/
      assert_select 'div.news_title a', :text => 'Desvincular'
    end

  end

  test "should show event without create related news links for creador_eventos_irekia" do
    login_as(:creador_eventos_irekia)

    get :show, :id => documents(:current_event)
    assert_response :success
    assert assigns(:event)

    assert_select 'div.related_news' do
      assert_select 'ul.edit_links', :count => 0
    end

  end

  # Test event edit and update actions
  test "should get edit event form" do
    login_as(:jefe_de_gabinete)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    get :edit, :id => documents(:current_event)
    assert assigns(:event)

    # comprobamos todos los campos del formulario
    ["politicians_tag_list", "speaker", "title_es", "place", "city", "location_for_gmaps", "all_journalists", "only_photographers"].each do |name|
      assert_select "input#event_#{name}"
    end

    assert_select 'div.is_private_radio_options'
    assert_select "input#event_is_private__1" # uso privado
    assert_select "input#event_is_private_0[checked=checked]"  # evento público

    assert_select "input#event_all_journalists"
    assert_select "input#event_only_photographers"

  end


  test "should get edit event form for private event" do
    login_as(:jefe_de_gabinete)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    get :edit, :id => documents(:private_event)
    assert_response :success

    assert_select 'form', :action => /events/

    # Comprobamos todos los campos del formulario
    ["politicians_tag_list", "speaker", "title_es", "place", "city", "location_for_gmaps", "all_journalists", "only_photographers"].each do |name|
      assert_select "input#event_#{name}"
    end

    assert_select 'div.is_private_radio_options'
    assert_select "input#event_is_private__1[checked=checked]" # uso privado
    assert_select "input#event_is_private_0"  # evento público

    assert_select 'input#event_all_journalists[checked]', :count => 0
    assert_select 'input#event_only_photographers[checked]', :count => 0

  end


  test "should get edit private event form if user can create private and public events" do
    login_as(:secretaria)
    get :edit, :id => documents(:private_event)
    assert_response :success
    assert_select 'form', :action => /events/

    # comprobamos todos los campos del formulario
    ["politicians_tag_list", "speaker", "title_es", "place", "city", "location_for_gmaps", "all_journalists", "only_photographers"].each do |name|
      assert_select "input#event_#{name}"
    end

    assert_select 'div.is_private_radio_options'
    assert_select "input#event_is_private__1[checked=checked]" # uso privado
    assert_select "input#event_is_private_0"  # evento público

    assert_select 'input#event_all_journalists[checked]', :count => 0
    assert_select 'input#event_only_photographers[checked]', :count => 0

  end


  test "should not get edit event form" do
    login_as(:secretaria_interior)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    get :edit, :id => documents(:current_event)
    assert_response :redirect
  end


  test "should update shared event" do
    login_as(:jefe_de_gabinete)
    e = documents(:current_event)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours
    assert_no_difference('Event.count') do
      post :update, :id => e.id,
                    :event => {"starts_at(1i)" => starts_at.year.to_s,
                               "starts_at(2i)" => starts_at.month.to_s,
                               "starts_at(3i)" => starts_at.day.to_s,
                               "ends_at(1i)" => ends_at.year.to_s,
                               "ends_at(2i)" => ends_at.month.to_s,
                               "ends_at(3i)" => ends_at.day.to_s,
                               "title_es"   => 'El nuevo tema del evento',
                               "is_private" => '0',
                               "alertable" => true}
    end
    assert_equal 'El nuevo tema del evento', assigns(:event).title
    assert_response :redirect
    assert_redirected_to sadmin_event_path(:id => assigns(:event).id)

  end

  test "should change public shared event to private shared event" do
    login_as(:secretaria)
    e = documents(:current_event)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours
    assert_no_difference('Event.count') do
      post :update, :id => e.id,
                    :event => {"starts_at(1i)" => starts_at.year.to_s,
                               "starts_at(2i)" => starts_at.month.to_s,
                               "starts_at(3i)" => starts_at.day.to_s,
                               "ends_at(1i)" => ends_at.year.to_s,
                               "ends_at(2i)" => ends_at.month.to_s,
                               "ends_at(3i)" => ends_at.day.to_s,
                               "title_es"       => 'El nuevo tema del evento',
                               "is_private" => '1'}
    end
    assert assigns(:event).is_private?, 'Updated event should be private'
    assert_equal "1", assigns(:event).is_private, "Schedule should be 1"
    assert_equal 'El nuevo tema del evento', assigns(:event).title
    assert_response :redirect
    assert_redirected_to sadmin_event_path(:id => assigns(:event).id)

  end


  test "secreataria should see create event buttons" do
    login_as(:secretaria)

    get :index
    assert_response :success

    assert_select 'div.create_links ul.edit_links' do
      assert_select 'li', :count => 1
      assert_select 'li a', 'Crear Evento'
    end
  end


  test "jefe de gabinete de interior should see one create event button" do
    login_as(:jefe_de_gabinete_de_interior)

    get :index
    assert_response :success

    assert_select 'div.create_links ul.edit_links' do
      assert_select 'li', :count => 1
      assert_select 'li a', 'Crear Evento'
    end
  end

  test "should get new event form if user can create private and public events" do
    login_as(:secretaria)
    get :new
    assert_response :success
    assert_select 'form', :action => /events/

    # Comprobamos todos los campos del formulario
    ["politicians_tag_list", "speaker", "title_es", "place", "city", "location_for_gmaps", "all_journalists", "only_photographers"].each do |name|
      assert_select "input#event_#{name}"
    end

    assert_select 'div.is_private_radio_options', :count => 1 # siempre está porque dentro están las opciones de uso privado y agenda compartida además de las agendas privadas
    assert_select "input#event_is_private__1" # uso privado
    assert_select "input#event_is_private_0"  # evento público
  end

  test "should be redirected does not have event modification permission" do
    login_as(:secretaria_interior)
    get :new
    assert_redirected_to new_session_path
    assert_not_authorized
  end

  test "miembro de departamento cannot create events" do
    login_as(:miembro_que_modifica_noticias)
    get :index
    assert_response :success
    # No tiene opcion de añadir evento
    assert_select 'div.create_links ul.edit_links', 0

    get :new
    assert_not_authorized
  end

  test "creador_eventos_privadas can sees no visibility option" do
    login_as(:creador_eventos_privadas)
    get :index
    assert_response :success
    assert_select 'div.create_links ul.edit_links a', "Crear Evento"

    get :new

    # Comprobamos todos los campos del formulario
    ["politicians_tag_list", "speaker", "title_es", "place", "city", "location_for_gmaps"].each do |name|
      assert_select "input#event_#{name}"
    end
    ["all_journalists", "only_photographers"].each do |name|
      assert_select "input#event_#{name}", :count => 0
    end

    assert_select 'div.is_private_radio_options', :count => 1
    assert_select "input[type=hidden][value=1][name*=is_private]" # eventos privados
    assert_select "input#event_is_private_0", :count => 0  # no tiene permiso
  end

  test "creador_eventos_privadas can not create public events" do
    login_as(:creador_eventos_privadas)

    # Si intentamos publicar en irekia, no nos deja
    post :create, :event => {:title_es => "Nuevo evento", :starts_at => Time.zone.now, :ends_at => Time.zone.now + 3.hours, :organization_id => organizations(:interior).id, :is_private => "0"}
    assert_template 'new'
    assert_equal true, assigns(:event).errors[:base].include?("No puedes crear eventos de este tipo")
  end


  test "creador_eventos_irekia can add events" do
    login_as(:creador_eventos_irekia)
    get :index
    assert_response :success
    assert_select 'div.create_links ul.edit_links a', "Crear Evento"
  end

  test "check new event form fields" do
    login_as(:creador_eventos_irekia)
    get :new

    # Comprobamos todos los campos del formulario
    ["politicians_tag_list", "speaker", "title_es", "place", "city", "location_for_gmaps", "all_journalists", "only_photographers"].each do |name|
      assert_select "input#event_#{name}"
    end

    assert_select 'div.is_private_radio_options'
    assert_select "input#event_is_private__1", :count => 0 # no puede crear eventos compartidos de uso privado
    assert_select "input#event_is_private_0", :count => 1  # eventos públicos
  end

  test "creador_eventos_irekia can create only irekia events" do
    login_as(:creador_eventos_irekia)
    # Si intentamos publicar en privado, no nos deja
    post :create, :event => {:title_es => "Nuevo evento", :starts_at => Time.zone.now, :ends_at => Time.zone.now + 3.hours, :organization_id => organizations(:interior).id, :is_private => "1"}
    assert_template 'new'
    assert_equal true, assigns(:event).errors[:base].include?("No puedes crear eventos de este tipo")
  end

  test "creador_eventos_irekia cannot edit private news" do
    login_as(:creador_eventos_irekia)
    get :show, :id => documents(:private_event)
    assert_response :success
    # No hay boton de modificar
    assert_select 'ul#edit_links a', :text => "modificar", :count => 0
    # Si intentamos modificarlo, no nos deja
    get :edit, :id => documents(:private_event)
    assert_redirected_to new_session_path
    assert_not_authorized

    put :update, :id => documents(:private_event), :event => {:title_es => "cambio titulo"}
    assert_redirected_to new_session_path
    assert_not_authorized
  end

  test "should create new public event with location taken from event_locations" do
    login_as(:jefe_de_gabinete)

    starts_at = Time.zone.now + 1.day
    ends_at = starts_at + 3.hours

    assert_difference('Event.count') do
      post :create, :event => {"starts_at(1i)" => starts_at.year.to_s,
                               "starts_at(2i)" => starts_at.month.to_s,
                               "starts_at(3i)" => starts_at.day.to_s,
                               "ends_at(1i)" => ends_at.year.to_s,
                               "ends_at(2i)" => ends_at.month.to_s,
                               "ends_at(3i)" => ends_at.day.to_s,
                               "title_es"   => 'El tema del evento',
                               "organization_id" => organizations(:lehendakaritza).id,
                               "place" => event_locations(:el_lehendakaritza).place,
                               "city" => event_locations(:el_lehendakaritza).city,
                               "location_for_gmaps" => event_locations(:el_lehendakaritza).address,
                               "is_private" => "0"}
    end
    assert !assigns(:event).is_private?
    assert_redirected_to sadmin_event_url(:id => assigns(:event).id, :fresh => 1)
    assert_equal event_locations(:el_lehendakaritza).lat, assigns(:event).lat
    assert_equal event_locations(:el_lehendakaritza).lng, assigns(:event).lng
  end

  test "staff_chief can see event type checkboxes" do
    login_as(:jefe_de_gabinete)
    get :new
    assert_response :success

    assert_select "input#event_is_private__1" # puede crear eventos privados
    assert_select "input#event_is_private_0"  # puede crear eventos publicos

  end


  # Acceso para políticos con diferentes permisos
  test "politician without permissions on agenda is redirected" do
    login_as(:politician_one)
    get :index
    assert_response :redirect
  end

  test "politician with news permisson is redirected" do
    login_as(:politician_interior)
    get :index
    assert_response :redirect
  end

  test "politician with events permisson can see index" do
    login_as(:politician_lehendakaritza)
    get :index
    assert_response :success
  end


  test "autocomplete for event news title" do
    login_as(:jefe_de_prensa)
    post :auto_complete_for_event_related_news_title, :value => 'xxx', :id => documents(:passed_event).id
    assert_response :success
  end

  test "in_place edit for event news title" do
    login_as(:jefe_de_prensa)
    event = documents(:current_event)
    assert_equal [], event.news

    news = documents(:one_news)

    assert_difference("RelatedEvent.count", 1) do
      xhr :post, :set_event_related_news_title, :value => news.title, :id => event.id, :format => :js
      assert_response :success
    end

    event.reload
    news.reload
    assert_equal [documents(:one_news)], event.news
    assert_equal [event], news.events
  end

  test "should delete pending unsent alerts and not schedule new ones if event is set as private" do
    login_as(:admin)
    event = documents(:event_with_unsent_alert)
    assert event.alerts.unsent.count != 0
    put :update, :id => event.id, :event => {:is_private => "1", :starts_at => 3.hours.from_now, :ends_at => 4.hours.from_now}
    event.reload
    assert event.alerts.unsent.count == 0
  end

  test "setting alert_this_change to true in private_event should not schedule alerts" do
    login_as(:admin)
    event = documents(:private_event)
    assert event.department.subscriptions.count > 0
    # the javascript in the page should not allow you to do this anyway
    put :update, :id => event.id, :event => {:alert_this_change => "1", :starts_at => 3.hours.from_now, :ends_at => 4.hours.from_now}
    event.reload
    assert_equal 0, event.alerts.unsent.count
  end

end
