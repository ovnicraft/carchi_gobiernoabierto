require 'test_helper'

class EventTest < ActiveSupport::TestCase

  def setup
    UserActionObserver.current_user = users(:admin).id
  end

  test "default values for non obligatory arguments" do
    # starts_at, ends_at and title are obligatory
    e = Event.new(:starts_at => Time.zone.now+1.day, :ends_at => Time.zone.now + 1.day + 30.minutes, :title => "Test", :organization => organizations(:lehendakaritza))
    assert e.valid?

    # by default the event is
    #   - private because there is no default publication date
    assert e.is_private?

  end

  test "validate presence of dates and title" do
    e = Event.new(:starts_at => Time.zone.now+1.day, :ends_at => Time.zone.now + 1.day + 30.minutes, :title => "Test", :organization => organizations(:lehendakaritza))
    assert e.valid?

    e = Event.new(:ends_at => Time.zone.now + 1.day + 30.minutes, :title => "Test", :organization => organizations(:lehendakaritza))
    assert !e.valid?

    e = Event.new(:starts_at => Time.zone.now+1.day, :title => "Test", :organization => organizations(:lehendakaritza))
    assert !e.valid?

    e = Event.new(:starts_at => Time.zone.now+1.day, :ends_at => Time.zone.now + 1.day + 30.minutes, :organization => organizations(:lehendakaritza))
    assert !e.valid?
  end

  test "body is optional" do
    e = Event.new(:starts_at => Time.zone.now+1.day, :ends_at => Time.zone.now + 1.day + 30.minutes, :title => "Test", :organization => organizations(:lehendakaritza))
    assert e.valid?
  end

  test "end date is later than start date" do
    e = Event.new(:starts_at => Time.zone.now+1.day, :title => "Test", :organization => organizations(:lehendakaritza))
    e.ends_at = e.starts_at - 1.second
    e.valid?
    assert !e.valid?
    assert_equal ["La fecha de fin debe ser posterior a la de inicio"], e.errors["base"]
  end

  test "one day method" do
    e = Event.new(:starts_at => (Time.zone.now+1.day).at_beginning_of_day + 3.hours, :ends_at => (Time.zone.now + 1.day).at_beginning_of_day + 3.hours + 30.minutes, :title => "Test", :body => "xx", :organization => organizations(:lehendakaritza))
    assert e.valid?
    assert e.one_day?

    e.ends_at = e.ends_at + 1.day
    assert !e.one_day?
  end

  test "department tag is assigned" do
    dept = organizations(:lehendakaritza)
    e = Event.new(:starts_at => Time.zone.now+1.day, :ends_at => Time.zone.now + 1.day + 30.minutes, :title => "Test", :organization => organizations(:lehendakaritza))
    e.organization = dept
    assert e.save
    assert e.tag_list.include?(dept.tag_name)


    org = organizations(:emakunde)
    e.organization = org
    assert e.save
    assert_equal org, e.organization
    assert_equal dept, e.department
    assert e.tag_list.include?(dept.tag_name)
  end

  test "has hour method" do
    e = Event.new(:starts_at => Time.zone.now+1.day, :ends_at => Time.zone.now + 2.days + 30.minutes, :title => "Test", :organization => organizations(:lehendakaritza))
    assert !e.one_day?
    assert e.has_hour?
  end

  test "days lists for multiple days events" do
    start_day = Time.zone.now.at_beginning_of_month
    end_day = start_day + 2.days
    e = Event.new(:starts_at => start_day, :ends_at => end_day, :title => "2 days event test", :organization => organizations(:lehendakaritza))
    assert_equal 1, e.day
    assert_equal [1,2,3], e.days

    start_day = Time.zone.now.at_end_of_month - 1.day
    end_day = start_day + 2.days
    e = Event.new(:starts_at => start_day, :ends_at => end_day, :title => "2 days event test", :organization => organizations(:lehendakaritza))
    assert_equal start_day.day, e.day
    assert_equal (start_day.day .. start_day.at_end_of_month.day).to_a, e.days

  end

  test "publication date assignment" do
    start_day = Time.zone.now
    end_day = Time.zone.now + 1.hour

    # Private event (:is_private => "1") is never published
    e = Event.new(:starts_at => start_day, :ends_at => end_day, :is_private => "1", :title => "Test", :organization => organizations(:lehendakaritza))
    assert e.save
    assert e.is_private?
    assert !e.published?
    assert_nil e.published_at

    # Public events (:is_private => "0") in Irekia are published when confirmed.
    e = Event.new(:starts_at => start_day, :ends_at => end_day, :title => "Test", :is_private => "0", :organization => organizations(:lehendakaritza))
    assert e.save
    assert !e.is_private?
    assert_not_nil e.published_at

    # Published at is not changed when event is updated unless confirmed_at is changed
    assert e.update_attribute(:published_at, Time.zone.now - 1.day)
    assert_equal (Time.zone.now - 1.day).to_date, e.published_at.to_date


  end


  test "special irekia tags" do
     e = documents(:passed_event)
     assert e.tag_list.include?("Irekia::Actos")
  end

  test "microformat body" do
    e = documents(:current_event)

    assert_equal "MyText", e.body
    assert_equal "MyText", e.microformat_body
  end


  test "long event" do
    e = documents(:long_event)

    start_month = e.month
    end_month = e.ends_at.month

    # p e.inspect
    # p ".................start month: #{start_month}"
    # p ".................end month: #{end_month}"
    start_month_events = Event.month_events(e.month, e.year)
    end_month_events = Event.month_events(e.ends_at.month, e.ends_at.year)

    assert_equal true, start_month_events.detect {|evt| evt.id.eql?(e.id)}.present?
    assert_equal true, end_month_events.detect {|evt| evt.id.eql?(e.id)}.present?

    # p "........ first day #{e.starts_at.day}"
    # p "........ last day #{e.starts_at.at_end_of_month.day}"
    start_month_days = (e.starts_at.day..e.starts_at.at_end_of_month.day).to_a
    end_month_days = (1..e.ends_at.day).to_a
    assert_equal start_month_days, e.days
    assert_equal end_month_days, e.days(e.ends_at.month, e.ends_at.year)

    e = Event.new(:starts_at => Time.zone.now.at_beginning_of_month - 10.days,
                  :ends_at   => Time.zone.now.at_end_of_month + 10.days,
                  :title => "Test", :organization => organizations(:lehendakaritza))
    assert_equal true, e.valid?

    assert_equal ((Time.zone.now.at_beginning_of_month - 10.days).day..(Time.zone.now.at_beginning_of_month - 10.days).at_end_of_month.day).to_a, e.days(e.starts_at.month, e.starts_at.year)

    assert_equal (1..(Time.zone.now.at_end_of_month + 10.days).day).to_a, e.days(e.ends_at.month, e.ends_at.year)

  end

  test "first day" do
    e = documents(:long_event)
    assert_equal e.starts_at.day, e.first_day(e.starts_at.month, e.starts_at.year)
    assert_equal 1, e.first_day(e.ends_at.month, e.ends_at.year)
  end


  test "month events for calendar view" do
    month = 3
    year = 2009
    events = Event.month_events_by_day4cal(month, year)

    # p "............. eventos en marzo:"
    # events[month].each do |day, evts|
    #   p "day: #{day}"
    #   p "eventos: #{evts.map {|e| e.pretty_dates}.join('\n')}"
    # end

    assert_equal 2, events[month-1].size
    assert_equal 2, events[month].size
    assert_equal 2, events[month+1].size
  end

  test "month events between two years" do
    month = 1
    year = 2009
    events = Event.month_events_by_day4cal(month, year)

    assert_equal 2, events[12].size
    assert_equal 2, events[month].size
    assert_nil events[month+1]

    month = 12
    year = 2008
    events = Event.month_events_by_day4cal(month, year)

    # p "............. eventos en dic 2008:"
    # events[month].each do |day, evts|
    #   p "day: #{day}"
    #   p "eventos: #{evts.map {|e| e.pretty_dates}.join('\n')}"
    # end

    assert_equal 2, events[12].size
    assert_equal 2, events[1].size
    assert_nil events[11]

  end


  test "fill lat lng data" do
    e = Event.new(:starts_at => Time.zone.now, :ends_at => Time.zone.now + 1.hour, :title => "Test", :organization => organizations(:lehendakaritza))
    assert_equal true, e.save
    assert_nil e.lat
    assert_nil e.lng

    e.location_for_gmaps = "c/Mayor"
    e.city = "Bilbao"
    assert_equal true, e.save
    assert_not_nil  e.lat
    assert_not_nil e.lng

    e.location_for_gmaps = ""
    e.city = ""
    assert_equal true, e.save
    assert_nil e.lat
    assert_nil e.lng

  end

  test "location for gmaps required if event is public and place is provided" do
    e = Event.new(:starts_at => Time.zone.now, :ends_at => Time.zone.now + 1.hour, :title => "Test", :organization => organizations(:lehendakaritza), :is_private => "0")
    assert_equal true, e.save
    assert_equal true, e.is_public?
    assert_nil e.lat
    assert_nil e.lng

    # ponemos un sitio que no existe en la lista de ubicaciones
    e.place = 'Palacio Euskalduna'
    assert_equal true, !e.save
    assert_equal ["no puede estar vacío"], e.errors[:city]
    assert_equal ["no puede estar vacío"], e.errors[:location_for_gmaps]

    # ponemos un sitio que sí está en la lista
    eloc = event_locations(:el_zamudio)
    e.place = eloc.place
    e.city= eloc.city
    e.location_for_gmaps = eloc.address
    assert_equal true, e.save
    assert_equal eloc.lat, e.lat
    assert_equal eloc.lng, e.lng
  end

  test "location for gmaps not required for private (:is_private => '1') events" do
    e = Event.new(:starts_at => Time.zone.now, :ends_at => Time.zone.now + 1.hour, :title => "Test", :organization => organizations(:lehendakaritza), :is_private => "1")
    assert_equal true, e.is_private?
    assert_equal true, e.save
    assert_nil e.lat
    assert_nil e.lng

    e.place = 'Palacio Euskalduna'
    assert_equal true, e.save
  end


  test "should create alert" do
    event = documents(:event_without_scheduled_alerts)
    assert_equal 0, event.alerts.count
    # Movemos la fecha un dia => deberia crear alerta para periodista
    event.starts_at = event.starts_at + 5.days
    event.ends_at = event.ends_at + 5.days
    assert_equal true, event.save
    assert_equal 2, event.journalist_alert_version
    assert_equal 3, event.alerts.for_journalists.count

    assert_equal [nil], event.alerts.for_journalists.map {|a| a.notify_about}.uniq
    spammable = event.alerts.for_journalists.map {|a| a.spammable}

    assert_equal true, spammable.include?(users(:periodista_con_alertas))
    assert_equal true, spammable.include?(users(:periodista_con_alertas_en_euskera))
    assert_equal true, spammable.include?(users(:periodista))
  end


  test "should modify unsent alerts" do
    event = documents(:event_with_unsent_alert)
    assert_equal 2, event.alerts.unsent.for_journalists.count

    recipients = event.alerts.for_journalists.collect {|a| a.spammable}
    assert_equal true, recipients.include?(users(:periodista_con_alertas))
    assert_equal true, recipients.include?(users(:periodista_con_alertas_en_euskera))

    # Movemos la fecha un dia => deberia crear alerta para periodista
    event.starts_at = event.starts_at + 7.days
    event.ends_at = event.ends_at + 7.days
    assert_equal true, event.save
    assert_equal 2, event.journalist_alert_version
    assert_equal 3, event.alerts.unsent.for_journalists.count
    recipients = event.alerts.unsent.for_journalists.collect {|a| a.spammable}
    assert_equal true, recipients.include?(users(:periodista_con_alertas))
    assert_equal true, recipients.include?(users(:periodista))
    assert_equal true, !recipients.include?(users(:periodista_sin_suscripciones))
    assert_equal true, recipients.include?(users(:periodista_con_alertas_en_euskera))

    # Cambiamos el body, y no cambiar la version ni el nº de alertas
    event.body_es = "Changed"
    assert_equal true, event.save
    assert_equal 2, event.journalist_alert_version
    assert_equal 3, event.alerts.unsent.for_journalists.count
    recipients = event.alerts.unsent.for_journalists.collect {|a| a.spammable}
    assert_equal true, recipients.include?(users(:periodista_con_alertas))
    assert_equal true, recipients.include?(users(:periodista))
    assert_equal true, !recipients.include?(users(:periodista_sin_suscripciones))
    assert_equal true, recipients.include?(users(:periodista_con_alertas_en_euskera))

    # Si despublicamos el evento el evento se convierte en alertable==false y se genera
    # nueva versión pero no se spammea a nadie
    event.published_at = nil
    assert event.save
    assert_equal 3, event.journalist_alert_version
    assert_equal 0, event.alerts.unsent.for_journalists.count

    # Volvemos a publicar
    event.published_at = Time.zone.now
    assert event.save
    assert_equal 4, event.journalist_alert_version
    assert_equal 3, event.alerts.unsent.for_journalists.count
    recipients = event.alerts.unsent.for_journalists.collect {|a| a.spammable}
    assert recipients.include?(users(:periodista_con_alertas))
    assert recipients.include?(users(:periodista))
    assert !recipients.include?(users(:periodista_sin_suscripciones))
    assert recipients.include?(users(:periodista_con_alertas_en_euskera))

    # Borramos el evento, y desaparecen las alertas y no se programan nuevas
    event.deleted = true
    assert event.save
    assert_equal 5, event.journalist_alert_version
    assert_equal 0, event.alerts.unsent.for_journalists.count
  end

  test "should modify sent alerts" do
    event = documents(:event_with_sent_alert)
    assert_equal 1, event.alerts.sent.for_journalists.count
    # Movemos la fecha un dia => deberia crear alerta para periodista
    event.starts_at = event.starts_at + 1.day
    event.ends_at = event.ends_at + 1.day
    assert event.save
    assert_equal 2, event.journalist_alert_version
    # Una enviada para periodista_con_alertas, otra sin enviar para periodista_con_alertas y otra no enviada para periodista_con_alertas_eu
    # y también para periodista pero no para periodista_sin_suscripciones

    assert_alerts_to_send_for_event_with_sent_alerts(event)

    # Cambiamos el body, y no cambiar la version ni el nº de alertas
    event.body_es = "Changed"
    assert event.save
    assert_equal 2, event.journalist_alert_version
    assert_equal 4, event.alerts.for_journalists.count
    assert event.alerts.unsent.for_journalists.first.spammable == users(:periodista_con_alertas)

    # Despublicamos el evento y manda alerta a quien ya se le habia mandado
    event.published_at = nil
    assert event.save
    assert_equal 3, event.journalist_alert_version
    # Una la que ya se le había mandado, y otra la nueva para decirle que ya no está confirmado
    assert_equal 1, event.alerts.unsent.for_journalists.count
    assert event.alerts.unsent.for_journalists.first.spammable == users(:periodista_con_alertas)

    # Volvemos a publicar
    event.published_at = Time.zone.now
    assert event.save
    assert_equal 4, event.journalist_alert_version
    assert_alerts_to_send_for_event_with_sent_alerts(event)

    # Borramos el evento, y tiene que aparecer la alerta
    event.deleted = true
    assert event.save
    assert_equal 5, event.journalist_alert_version
    assert_equal 1, event.alerts.unsent.for_journalists.count
    assert event.alerts.unsent.for_journalists.first.spammable == users(:periodista_con_alertas)
  end


  def assert_alerts_to_send_for_event_with_sent_alerts(event)
    assert_equal 4, event.alerts.for_journalists.count

    assert_equal 1, event.alerts.sent.for_journalists.count
    recipients = event.alerts.sent.for_journalists.collect {|a| a.spammable}
    assert recipients.include?(users(:periodista_con_alertas))

    assert_equal 3, event.alerts.unsent.for_journalists.count
    recipients = event.alerts.unsent.for_journalists.collect {|a| a.spammable}
    assert recipients.include?(users(:periodista_con_alertas))
    assert recipients.include?(users(:periodista))
    assert !recipients.include?(users(:periodista_sin_suscripciones))
    assert recipients.include?(users(:periodista_con_alertas_en_euskera))
    assert event.alerts.for_journalists.first.spammable == users(:periodista_con_alertas)

  end

 if Settings.optional_modules.streaming
  test "alerts about streaming about" do
    event = documents(:event_with_streaming)
    assert_equal 3, event.alerts.unsent.for_staff.count

    # Movemos la fecha un dia => deberia crear alerta para periodista
    event.starts_at = event.starts_at + 7.days
    event.ends_at = event.ends_at + 7.days
    assert_difference 'event.staff_alert_version', +2 do # la alerta de DepartmentEditor lo aumenta una vez y la de operadores de streaming otra
      assert event.save
    end

    assert_equal 2, event.alerts.unsent.for_streaming_staff.count # operador de streaming y room manager

    current_alert_ids = event.alerts.unsent.for_staff.collect(&:id).sort

    recipients = event.alerts.unsent.for_staff.collect(&:spammable)
    check_recipients(event, recipients)

    # Cambiamos el body, y no cambiar la version ni el nº de alertas
    event.body_es = "Changed"
    assert_no_difference 'event.staff_alert_version' do
      assert event.save
    end
    assert_equal current_alert_ids, event.alerts.unsent.for_staff.collect(&:id).sort
    recipients = event.alerts.unsent.for_staff.collect(&:spammable)
    check_recipients(event, recipients)

    # Despublicamos el evento y desaparece la alerta
    event.published_at = nil
    assert_difference 'event.staff_alert_version', +2 do
      assert event.save
    end
    assert_equal 0, event.alerts.unsent.for_staff.count


    # Volvemos a publicar
    event.published_at = Time.zone.now
    assert_difference 'event.staff_alert_version', +2 do
      assert event.save
    end

    recipients = event.alerts.unsent.for_staff.collect(&:spammable)
    check_recipients(event, recipients)

    # Quitamos el streaming en agencia y desaparece la alerta
    event.streaming_live = false
    assert_difference 'event.staff_alert_version', +2 do
      assert event.save
    end
    event.reload
    assert_equal 2, event.alerts.unsent.for_staff.count # Para el creador y el Jefe de Departamento
    recipients = event.alerts.unsent.for_staff.collect(&:spammable)
    assert recipients.include?(event.creator)
    # Hay alerta para los jefes de departamento
    DepartmentEditor.where({:department_id => event.department.id}).each do |editor|
      assert recipients.include?(editor)
    end

  end

  test "should not create alert for event_with_streaming_without_alerts" do
    event = documents(:event_with_streaming_without_alerts)
    assert_equal 0, event.alerts.for_streaming_staff.count
    event.streaming_for = "en_diferido"
    assert_no_difference 'EventAlert.for_streaming_staff.count' do
      assert event.save
    end
  end

  test "changing to streaming without alerts should modify alerts" do
    event = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    assert_equal 3, event.alerts.sent.for_staff.count
    alerted_people = event.alerts.sent.collect(&:spammable)

    assert_equal 0, event.alerts.unsent.for_staff.count

    # Nos aseguramos que la sala está libre
    stream_flows(:sf_without_alerts).day_events.each do |evt|
      assert evt.update_attributes(:published_at => nil, :streaming_for_en_diferido => 1, :streaming_for_irekia => 0, :starts_at => evt.starts_at - 1.day, :ends_at => evt.ends_at - 1 .day)
    end


    # Changing the stream_flow schedules a new alert
    event.stream_flow = stream_flows(:sf_without_alerts)
    event.streaming_for_en_diferido = 1
    event.streaming_for_irekia = 0


    assert_difference 'event.staff_alert_version', 2 do
      assert event.save!
    end

    # Journalists get alerts
    event_department_id = event.organization.is_a?(Department) ? event.organization_id : event.organization.department.id
    active_subscriptors_for_this_department = Subscription.active.where("subscriptions.department_id = #{event_department_id}").map(&:user_id)
    active_subscriptors_for_this_department.each do |subscription|
      assert event.alerts.for_journalists.collect(&:spammable_id).include?(subscription)
    end

    recipients = event.alerts.for_staff.collect(&:spammable)
    # Las alertas deberian ser para los mismos que alertamos antes
    alerted_people.each do |r|
      assert recipients.include?(r), "Expected #{r.class} #{r.id} to be among the new recipients"
    end

    # El jefe de prensa y el creador del evento también reciben alerta
    assert recipients.include?(event.creator)
    DepartmentEditor.where("department_id=#{event_department_id}").each do |editor|
      assert recipients.include?(editor)
    end

    # Y no se generan alertas para los responsables de la nueva sala, porque esta sala es "sin alertas"
    stream_flows(:sf_without_alerts).room_managers.each do |r|
      assert !recipients.include?(r), "Expected #{r.class} #{r.id} not to be among the new recipients"
    end

  end

  test "changing the stream_flow of an event should schedule new alert" do
    event = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    assert_equal 3, event.alerts.for_staff.count
    # Changing the stream_flow schedules a new alert
    event.stream_flow = stream_flows(:sf_three)
    event.streaming_for_en_diferido = 1
    event.streaming_for_irekia = 0

    assert event.save
    recipients = event.alerts.for_staff.collect(&:spammable)
    check_recipients(event, recipients)
    assert recipients.include?(users(:room_manager)) # Former room manager

    # El jefe de prensa y el creador del evento también reciben alerta
    event_department_id = event.organization.is_a?(Department) ? event.organization_id : event.organization.department.id
    assert recipients.include?(event.creator)
    DepartmentEditor.where("department_id=#{event_department_id}").each do |editor|
      assert recipients.include?(editor)
    end
  end

  test "should not schedule alerts about streaming for room managers and streaming operators for new event that is not published" do
    event = Event.new(:starts_at => Time.zone.now + 1.day, :ends_at => Time.zone.now + 1.day + 2.hours, :published_at => nil,
                      :title => 'Evento son confirmar', :organization_id => organizations(:lehendakaritza).id,
                      :irekia_coverage => true, :streaming_live => true,
                      :stream_flow => stream_flows(:sf_two), :streaming_for => 'irekia')
    assert event.save
    assert_equal 0, event.alerts.count


    # Publicamos el evento
    event.published_at = Time.zone.now
    assert event.save
    assert event.is_public?
    assert_equal Subscription.active.where("subscriptions.department_id = #{event.department.id}").count, event.alerts.for_journalists.count

    assert_equal 4, event.alerts.for_staff.count # para el room manager, el streaming operator y el jefe de prensa del departamento, el autor

    recipients = event.alerts.unsent.for_staff.collect(&:spammable)
    check_recipients(event, recipients)

    # Despublicamos
    event.published_at = nil
    assert event.save
    assert event.is_private?
    # No se ha enviado ninguna alerta y el evento está sin confirmar, por lo tanto no hay que envar alertas.
    assert_equal 0, event.alerts.for_staff.count
  end

  def check_recipients(event, recipients)
    # Hay alerta para el creador
    assert recipients.include?(event.creator)
    # Hay alerta para los jefes de departamento
    DepartmentEditor.where({:department_id => event.department.id}).each do |editor|
      assert recipients.include?(editor)
    end
    #
    # Hay alertas para los responsables de sala
    event.stream_flow.room_managers.each do |rm|
      assert recipients.include?(rm)
    end
    # Hay alerta para los operadores de streaming
    StreamingOperator.all.each do |so|
      assert recipients.include?(so)
    end
  end

  test "named scope with_streaming" do
    e = documents(:event_with_streaming)

    assert e.streaming_live?
    assert_not_nil e.stream_flow

    assert Event.with_streaming.detect {|evt| evt.id.eql?(e.id)}
  end
  test "streaming_for" do
    e = documents(:event_with_streaming)

    assert e.streaming_live?
    assert e.streaming_for_irekia?
    assert !e.streaming_for_en_diferido?
    assert_equal ['Irekia'], e.streaming_for_pretty.split(", ").sort

    # No puede estar en blanco.
    assert !e.update_attributes({:streaming_for_irekia => "0"})
    e.reload
    # assert !e.streaming_for_en_diferido?
    assert_equal 'irekia', e.streaming_for

    # Sí se puede sustituir
    e.update_attributes({:streaming_for_en_diferido => 1})
    assert !e.streaming_for_irekia?
    assert e.streaming_for_en_diferido?
    assert_equal ['En diferido'], e.streaming_for_pretty.split(", ").sort
  end

  test "do not set streaming_for to nil" do
    e = documents(:event_with_streaming)

    assert e.streaming_live?
    assert e.streaming_for_irekia?

    e.streaming_for_irekia = 0
    e.streaming_for_en_diferido = 0
    assert !e.valid?
  end

  test "set streaming_flow to nil when streaming_live is false" do
    e = documents(:event_with_streaming)

    assert e.streaming_live?
    assert e.streaming_for_irekia?
    assert_not_nil e.stream_flow

    assert e.streaming_live = 0
    assert e.save
    e.reload
    assert !e.streaming_live?
    assert_nil e.stream_flow
    assert e.streaming_for.blank?
    assert !e.streaming_for_irekia?
  end

  test "overlapped" do
    e = documents(:event_with_streaming)
    assert_equal 2, e.overlapped_streaming.size
  end

  test "validate streaming for when streaming live" do
    e = documents(:event_with_streaming)

    assert e.streaming_live?
    assert e.streaming_for_irekia?
    assert_not_nil e.stream_flow

    e.streaming_for_irekia = 0
    e.streaming_for_en_diferido = 0
    assert !e.valid?
    assert e.errors[:streaming_for]
  end
  test "deleting an events sets it to draft" do
    e = documents(:event_with_streaming)
    e.deleted = true
    assert e.save
    assert !e.published?
  end
  test "should not send alerts about changes when the event has already expired" do
    event = documents(:old_event_with_streaming_and_sent_alert_and_show_in_irekia)
    event.starts_at = event.starts_at + 1.hour
    old_journalist_alert_version = event.journalist_alert_version
    old_staff_alert_version = event.staff_alert_version
    assert_no_difference 'EventAlert.count' do
      event.save
    end
    assert_equal event.staff_alert_version, old_staff_alert_version
    assert_equal event.journalist_alert_version, old_journalist_alert_version
  end

  test "on_air" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now + 20.minutes, :ends_at => Time.zone.now + 2.hours)
    evt.stream_flow.update_attributes(:show_in_irekia => true, :event_id => evt.id)
    UserActionObserver.current_user = nil

    assert evt.on_air?
  end

  test "announced" do
    UserActionObserver.current_user = users(:admin)
    evt = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    evt.update_attributes(:starts_at => Time.zone.now + 20.minutes, :ends_at => Time.zone.now + 2.hours)
    evt.stream_flow.update_attributes(:announced_in_irekia => true, :event_id => evt.id)
    UserActionObserver.current_user = nil

    assert evt.announced?
  end
  test "cov_types_pretty" do
    assert_equal [], documents(:ma_yesterday_event).cov_types_pretty

    assert_equal ['audio', 'vídeo', 'fotos', 'streaming en Irekia'].sort, documents(:current_event_with_streaming).cov_types_pretty.sort
  end

  test "only photographers" do
    assert !documents(:current_event_with_streaming).only_photographers?
    assert documents(:event_with_tag_one).only_photographers?
    assert documents(:event_with_tag_one).only_photographers?
  end
  test  "next4streaming contains the events that are not translated" do
    I18n.locale = :eu
    assert Event.next4streaming.detect {|e| !e.translated_to?('eu')}
  end

  test "next4streaming contains events independent of the selected site" do
    evt = documents(:event_with_streaming)
    evt.starts_at = Time.zone.now + 5.minutes
    evt.ends_at = Time.zone.now + 1.hour
    evt.published_at = Time.zone.now
    evt.streaming_for='irekia'
    assert evt.save!

    assert Event.next4streaming.include?(evt)
  end
  test "setting alert_this_change to false should not schedule alerts for journalists" do
    event = documents(:event_with_streaming)
    assert_equal 0, event.alerts.unsent.for_journalists.count
    event.update_attributes(:streaming_live => false, :alert_this_change => "0")
    assert_equal 0, event.alerts.unsent.for_journalists.count
  end

  test "setting alert_this_change to true should schedule alerts for journalists" do
    event = documents(:event_with_streaming)
    assert_equal 0, event.alerts.unsent.for_journalists.count
    event.update_attributes(:streaming_live => false, :alert_this_change => "1")
    assert event.alerts.unsent.for_journalists.count != 0
  end
 end


  #
  #  Los métodos que se usan en el calendario están separados en el módulo Tools::Calendar.
  #  Comprobamos que están definidos.
  #
  test "included calendar methods" do
    e = documents(:current_event)
    ["one_day?", "has_hour?", "year", "month", "day", "first_day", "days"].each do |m|
      assert e.respond_to?(m)
    end

    ["month_events", "month_events_by_day", "month_events_by_day4cal"].each do |cm|
      assert Event.respond_to?(cm)
    end
  end


  test "is_destroyable? method" do
    assert documents(:private_event).is_destroyable?
    assert documents(:current_event).is_destroyable?
    assert !documents(:event_with_sent_alert).is_destroyable?
  end

  # HT
  # test "should tweet published event" do
  #   publication_date = Time.zone.now - 1.hour
  #   event = Event.new(:starts_at => publication_date, :ends_at => publication_date + 30.minutes, :title => "Test", :organization => organizations(:lehendakaritza), :published_at => 1.hour.ago)
  #   assert event.save
  #   assert event.tweets.count == 1
  #   assert event.tweets.first.tweet_at = publication_date - 3.days
  # end
  # 
  # test "should not tweet unpublished event" do
  #   publication_date = Time.zone.now - 1.hour
  #   event = Event.new(:starts_at => publication_date, :ends_at => publication_date + 30.minutes, :title => "Test", :organization => organizations(:lehendakaritza), :published_at => nil)
  #   assert event.save
  #   assert event.tweets.count == 0
  # end
  #
  # test "should not tweet private news" do
  #   publication_date = Time.zone.now - 1.hour
  #   event = Event.new(:starts_at => publication_date, :ends_at => publication_date + 30.minutes, :title => "Test", :organization => organizations(:lehendakaritza), :is_private => "1")
  #   assert event.save
  #   assert event.tweets.count == 0
  # end
  #
  # test "should not tweet event older than one month" do
  #   event = documents(:last_year_event)
  #   event.body_es = "Changed"
  #   assert_no_difference 'DocumentTweet.count' do
  #     event.save
  #   end
  #   assert_equal 0, event.tweets.count
  # end


  test "event without body should be considered as translated" do
    event = documents(:translated_event)
    assert event.translated_to?("eu")
  end

  test "event with body should be considered as untranslated" do
    event = documents(:untranslated_event)
    assert !event.translated_to?("eu")
  end


  test "should answer is_private" do
    # los eventos públicos tienen schedule_id = 0
    assert_equal "0", documents(:current_event).is_private
    assert_equal "1", documents(:private_event).is_private
  end

  test "should assign is_private 1" do
    e = documents(:current_event)
    assert !e.is_private?

    assert e.update_attribute(:is_private, "1")
    assert_equal "1", e.is_private
    assert e.is_private?
  end

  test "should assign is_private 0" do
    e = documents(:private_event)
    assert e.is_private?

    assert e.update_attribute(:is_private, "0")
    assert_equal "0", e.is_private
    assert !e.is_private?
  end

  test "should assigns is_private 100" do
    e = documents(:current_event)
    assert !e.is_private?

    assert e.update_attribute(:is_private, "100")
    assert_equal "1", e.is_private
    assert e.is_private?
  end



  test "named scope with_irekia_coverage" do
    cov_docs = Event.where({:irekia_coverage => true})
    no_cov_docs = Event.where({:irekia_coverage => false})

    assert !cov_docs.blank?
    assert !no_cov_docs.blank?

    wic = Event.with_irekia_coverage
    cov_docs.each do |doc|
      assert wic.detect {|evt| evt.id.eql?(doc.id)}, "El evento #{doc.title} tiene que salir en la lista de eventos con cobertura Irekia"
    end

    no_cov_docs.each do |doc|
      assert_nil wic.detect {|evt| evt.id.eql?(doc.id)}, "El evento #{doc.title} NO tiene que salir en la lista de eventos con cobertura Irekia"
    end

  end

  test "passed method" do
    assert documents(:passed_event).passed?
    assert !documents(:future_event).passed?

    e = documents(:current_event)
    e.update_attribute(:ends_at, Time.zone.now)
    assert e.passed?
    e.update_attribute(:ends_at, Time.zone.now+1.hour)
    assert !e.passed?
    e.update_attribute(:ends_at, Time.zone.now-1.hour)
    assert e.passed?

  end

  test "between method" do
    e = documents(:event_with_unsent_alert)
    assert e.between?(Time.zone.now.at_beginning_of_day.to_date, (Time.zone.now.at_beginning_of_day + 2.days).to_date)
  end

  test "future events list" do
    evt = documents(:future_event)

    events = Event.published.translated.future
    assert events.detect {|e| e.id.eql?(evt.id)}

    events = Event.published.translated.future.where(["starts_at <= ?", Time.zone.now + 3.days])
    assert !events.detect {|e| e.id.eql?(evt.id)}
  end

  test "should fill lat and lng using event locations" do
    eloc = event_locations(:el_lehendakaritza)
    e = Event.new(:starts_at => Time.zone.now+1.day, :ends_at => Time.zone.now + 1.day + 30.minutes,
                  :title => "Test", :organization => organizations(:lehendakaritza),
                  :place => eloc.place, :city => eloc.city, :location_for_gmaps => eloc.address
                  )
    assert e.valid?
    assert e.save

    assert_equal eloc.lat.to_s, e.lat.to_s
    assert_equal eloc.lng.to_s, e.lng.to_s
  end

  test "should fill lat and lng using event locations for empty address" do
    eloc = event_locations(:el_zamudio)
    e = Event.new(:starts_at => Time.zone.now+1.day, :ends_at => Time.zone.now + 1.day + 30.minutes,
                  :title => "Test", :organization => organizations(:lehendakaritza),
                  :place => eloc.place, :city => eloc.city, :location_for_gmaps => eloc.address
                  )
    assert e.valid?
    assert e.save

    assert_equal eloc.lat.to_s, e.lat.to_s
    assert_equal eloc.lng.to_s, e.lng.to_s
  end



  test "related news by event" do
    assert_equal [documents(:news_with_event).id], documents(:emakunde_passed_event).news_ids
    assert_equal [documents(:news_with_event).id], documents(:emakunde_passed_event).news.map {|n| n.id}

    assert_equal documents(:news_with_event).title, documents(:emakunde_passed_event).related_news_title
    assert_nil documents(:current_event).related_news_title
  end

  test "related events is deleted when the event is deleted" do
    assert_difference("RelatedEvent.count", -2) do
      documents(:emakunde_passed_event).destroy
    end
  end

  test "add news" do
    event = documents(:emakunde_passed_event)
    assert_equal [documents(:news_with_event).id],  event.news_ids

    assert_difference("RelatedEvent.count", 1) do
      event.news_ids = event.news_ids + [documents(:one_news).id]
    end
  end

  test "remove news" do
    event = documents(:emakunde_passed_event)
    assert_equal [documents(:news_with_event).id],  event.news_ids

    assert_difference("RelatedEvent.count", -1) do
      event.news_ids = []
    end
  end

  test "add and remove news" do
    event = documents(:emakunde_passed_event)
    assert_equal [documents(:news_with_event).id],  event.news_ids

    assert_no_difference("RelatedEvent.count") do
      event.news_ids = [documents(:one_news).id]
    end
  end

  test "set related_news_title" do
    event = documents(:current_event)
    assert_equal [],  event.news_ids

    assert_difference("RelatedEvent.count", 1) do
      event.related_news_title = documents(:one_news).title
    end

    assert_equal [documents(:one_news).id],  event.news_ids
  end

  test "empty related news title" do
    event = documents(:emakunde_passed_event)
    assert_equal [documents(:news_with_event).id],  event.news_ids

    res = ''
    assert_difference("RelatedEvent.count", -1) do
      res = event.related_news_title = ''
    end
    assert_equal 'buscar noticia', event.related_news_title
  end

  test "related videos for event" do
    assert_equal [videos(:video_with_event).id],  documents(:emakunde_passed_event).video_ids
    assert_equal [videos(:video_with_event).id],  documents(:emakunde_passed_event).videos.map {|n| n.id}
  end

  test "add video" do
    event = documents(:emakunde_passed_event)
    assert_equal [videos(:video_with_event).id],  event.video_ids

    assert_difference("RelatedEvent.count", 1) do
      event.video_ids = event.video_ids + [videos(:featured_video).id]
    end
  end

  test "remove video" do
    event = documents(:emakunde_passed_event)
    assert_equal [videos(:video_with_event).id],  event.video_ids

    assert_difference("RelatedEvent.count", -1) do
      event.video_ids = []
    end
  end

  test "add and remove video" do
    event = documents(:emakunde_passed_event)
    assert_equal [videos(:video_with_event).id],  event.video_ids

    assert_no_difference("RelatedEvent.count") do
      event.video_ids = [videos(:featured_video).id]
    end
  end



  test "set all journalists" do
    evt = documents(:event_with_tag_one)

    # Al principio es sólo para fotográfos
    assert evt.has_photographers?
    assert !evt.has_journalists?

    # Cambiamos a todos los periodistas
    evt.all_journalists = 1
    assert evt.save
    assert evt.has_photographers?
    assert evt.has_journalists?

    # Cambiamos a ningún periodista
    evt.all_journalists = 0
    evt.only_photographers = 0
    assert evt.save
    assert !evt.has_photographers?
    assert !evt.has_journalists?

  end

  test "should not schedule alerts for journalist without subscriptions" do
    event = Event.new :starts_at => 2.days.from_now, :ends_at => 2.days.from_now + 2.hours, :title_es => "Nuevo evento",
                      :organization_id => organizations(:lehendakaritza).id, :is_private => "0"
    assert_difference 'Event.count', +1 do
      event.save
    end

    assert event.alerts.count > 0
    assert !event.alerts.collect(&:spammable).include?(users(:periodista_sin_suscripciones)), "No debería crear alerta para periodista_sin_suscripciones"
  end


  test "set politicians with one name" do
    evt = documents(:current_event)
    assert evt.politicians.empty?

    evt.politicians_tag_list = tags(:tag_politician_lehendakaritza).name_es
    assert_equal true, evt.save

    evt.reload
    assert_equal users(:politician_lehendakaritza), evt.politicians.first
  end

  test "set politicians with two names" do
    evt = documents(:current_event)
    assert evt.politicians.empty?

    tag1 = tags(:tag_politician_lehendakaritza)
    tag2 = tags(:tag_politician_interior)
    evt.politicians_tag_list = "#{tag1.name_es}, #{tag2.name_es}"
    assert_equal true, evt.save

    evt.reload
    assert_equal 2, evt.politicians.size
    expected_ids = [users(:politician_lehendakaritza).id, users(:politician_interior).id].sort
    assert_equal expected_ids, evt.politicians.map {|politician| politician.id}.sort
  end

  test "change politicians names" do
    evt = documents(:current_event)
    assert evt.politicians.empty?

    tag1 = tags(:tag_politician_lehendakaritza)
    politician1 = Politician.find(tag1.kind_info)
    tag2 = tags(:tag_politician_interior)
    politician2 = Politician.find(tag2.kind_info)

    assert evt.update_attribute(:politicians_tag_list, tag1.name_es)
    evt.reload
    assert_equal politician1, evt.politicians.first


    assert evt.update_attribute(:politicians_tag_list, tag2.name_es)
    evt.reload
    assert_equal politician2, evt.politicians.first
  end

  test "should raise an error if politician name does not correspond to politician" do
    evt = documents(:current_event)
    assert evt.politicians.empty?

    evt.politicians_tag_list = "xxxxxx"
    assert !evt.valid?
  end

 if Settings.optional_modules.streaming
  test "new event without alertable attribute should not schedule alerts" do
    event = Event.new(:starts_at => 5.hours.from_now, :ends_at => 7.hours.from_now, :organization => organizations(:lehendakaritza), :title_es => "Evento sin alertas",
                      :alertable => false,
                      :published_at => Time.zone.now, # programaria alertas para periodistas
                      :streaming_live => true, :streaming_for => "irekia", :stream_flow => stream_flows(:sf_three) # programa alertas para staff
                      )

    journalist_alert_counter = EventAlert.for_journalists.count
    staff_alert_counter = EventAlert.for_staff.count

    event.save

    assert_equal journalist_alert_counter, EventAlert.for_journalists.count, "should not have scheduled alerts for journalists but it did"
    assert EventAlert.for_staff.count > staff_alert_counter
  end
 end

  test "changing alertable attribute in event_with_unsent_alert does not delete pending alerts and doesn't schedule new ones" do
    event = documents(:event_with_unsent_alert)
    journalist_pending_alert_ids = event.alerts.unsent.for_journalists.collect(&:id).sort
    assert event.alerts.unsent.for_journalists.count != 0
    staff_alert_counter = event.alerts.unsent.for_staff.count

    event.alertable = false
    event.save

    event.reload
    assert_equal journalist_pending_alert_ids, event.alerts.unsent.for_journalists.collect(&:id).sort
    assert_equal staff_alert_counter, event.alerts.unsent.for_staff.count
  end

  test "should delete pending unsent alerts and not schedule new ones if event is set as private" do
    event = documents(:event_with_unsent_alert)
    assert event.alerts.unsent.count != 0
    event.published_at = nil
    event.save
    event.reload
    assert event.alerts.unsent.count == 0
  end

  test "setting alert_this_change to true in private_event should not schedule alerts" do
    event = documents(:private_event)
    assert event.department.subscriptions.count > 0
    event.alert_this_change = "1"
    event.starts_at = 3.hours.from_now
    event.ends_at = 4.hours.from_now
    event.save
    event.reload
    assert_equal 0, event.alerts.unsent.count
  end


  test "changing event tags does not schedule new alerts" do
    event = documents(:current_event)
    assert_equal 0, event.alerts.unsent.count
    assert event.department.subscriptions.count > 0 # Nos aseguramos de que hay periodistas a los que debería notificarse
    assert event.created_by.present?
    assert event.alertable?
    assert event.alert_this_change
    event.tag_list_without_areas = ["este es un nuevo tag"] # En el formulario de la web se ponen los tags con este método
    assert event.save
    assert event.tag_list.include?('este es un nuevo tag')
    assert_equal 0, event.alerts.unsent.count # y por lo tanto el autor del evento tampoco recibe alerta
  end

  test "changing event's irekia coverage in future events does schedule new alert for event creator" do
    event = documents(:current_event)
    assert_equal 0, event.alerts.unsent.count
    assert event.created_by.present?
    # assert event.alertable?
    # assert event.alert_this_change
    assert !event.irekia_coverage?
    event.irekia_coverage = true
    # Nos aseguramos de que el evento acaba en el día de hoy pero en el futuro, porque si no no se programan nuevas alertas
    event.ends_at = Time.zone.now.end_of_day - 1.minute
    assert event.save
    assert event.irekia_coverage?
    assert event.alerts.unsent.count != 0
    assert_equal true, event.alerts.unsent.collect(&:spammable_id).include?(event.created_by)
  end

  test "changing event's irekia coverage in passed events does not schedule new alerts" do
    event = documents(:current_event)
    assert_equal 0, event.alerts.unsent.count
    assert event.created_by.present?
    # assert event.alertable?
    # assert event.alert_this_change
    assert !event.irekia_coverage?
    event.irekia_coverage = true
    # Nos aseguramos de que el evento acaba en el día de hoy pero en el futuro, porque si no no se programan nuevas alertas
    event.ends_at = Time.zone.now - 1.minute
    assert event.save
    assert event.irekia_coverage?
    assert_equal true, event.alerts.unsent.count == 0
    assert_equal false, event.alerts.unsent.collect(&:spammable_id).include?(event.created_by)
  end  

  test "should index to elasticsearch after save" do
    prepare_elasticsearch_test
    event = documents(:current_event)
    assert_deleted_from_elasticsearch event
    assert event.save
    assert_indexed_in_elasticsearch event
  end

  test "should delete from elasticsearch after destroy" do
    prepare_elasticsearch_test
    event = documents(:current_event)
    assert_deleted_from_elasticsearch event
    assert event.save
    assert_indexed_in_elasticsearch event
    assert event.destroy
    assert_deleted_from_elasticsearch event
  end

  context "syncronization between events areas and it's comments areas" do
    setup do
      @event = documents(:current_event)
      @event.comments.create(:body => "thoughtful comment", :user => users(:comentador_oficial))
    end

    should "have lehendakaritza area tag" do
      assert_equal [areas(:a_lehendakaritza)], @event.areas
      @event.comments.each do |comment|
        assert_equal [areas(:a_lehendakaritza).area_tag], comment.tags
      end
    end

    context "via area_tags=" do
      # This is what the form in admin/documents/edit_tags uses
      should "add new area to comment" do
        @event.area_tags= [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es]
        @event.save
        @event.reload
        assert @event.areas.include?(areas(:a_interior))
        @event.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        @event.area_tags = [areas(:a_interior).area_tag.name_es]
        @event.save
        @event.reload
        assert !@event.areas.include?(areas(:a_lehendakaritza))
        @event.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

      should "not sync tags that are not area tags" do
        new_tag = tags(:tag_politician_lehendakaritza)
        @event.area_tags = [new_tag.name_es]
        @event.save
        @event.reload
        assert @event.tags.include?(new_tag)
        @event.comments.each do |comment|
          assert !comment.tags.include?(new_tag)
        end
      end

    end

    context "via tag_list" do
      should "add new area to comment" do
        @event.tag_list.add areas(:a_interior).area_tag.name_es
        assert @event.save
        @event.reload
        assert @event.areas.include?(areas(:a_interior))
        @event.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        @event.tag_list.remove areas(:a_lehendakaritza).area_tag.name_es
        assert @event.save
        @event.reload
        assert !@event.areas.include?(areas(:a_lehendakaritza))
        @event.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

      should "not sync tags that are not area tags" do
        new_tag = tags(:tag_politician_lehendakaritza)
        @event.tag_list.add new_tag.name_es
        @event.save
        @event.reload
        assert @event.tags.include?(new_tag)
        @event.comments.each do |comment|
          assert !comment.tags.include?(new_tag)
        end
      end
    end
  end

  context "countable" do
    setup do
      @a_interior_event = Event.create(:starts_at => Time.zone.now+1.day, :ends_at => Time.zone.now + 1.day + 30.minutes, :title => "Test", :organization => organizations(:pacad), :area_tags => [areas(:a_interior).area_tag.name_es])
      @stats_counter = @a_interior_event.stats_counter
    end

    should "have correct area and department in stats_counter" do
      assert_equal areas(:a_interior).id,  @stats_counter.area_id
      assert_equal organizations(:pacad).id, @stats_counter.organization_id
      assert_equal organizations(:interior).id, @stats_counter.department_id
    end

    should "update stats_counter area" do
      @a_interior_event.update_attributes(:area_tags => [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es])
      assert_equal areas(:a_lehendakaritza).id,  @stats_counter.area_id
    end

    should "update stats_counter organization" do
      @a_interior_event.update_attributes(:organization_id => organizations(:emakunde).id)
      assert_equal organizations(:emakunde).id,  @stats_counter.organization_id
      assert_equal organizations(:lehendakaritza).id, @stats_counter.department_id
    end
  end

end
