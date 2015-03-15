require 'test_helper'

class StreamFlowTest < ActiveSupport::TestCase
 if Settings.optional_modules.streaming
  def setup
    UserActionObserver.current_user = users(:admin).id
  end

  test "events to be emitted" do

    e = documents(:event_with_streaming)
    if e.update_attributes(:starts_at => Time.zone.now+30.minutes, :ends_at => Time.zone.now+60.minutes)
      sf = stream_flows(:sf_two)

      tbe = Event.published.where(["stream_flow_id = :sf_id and starts_at <= :sdate and ends_at >= :edate", {:sf_id => sf.id, :sdate => Time.zone.now + 60.minutes, :edate => Time.zone.now}])
      assert_equal tbe.map {|e| e.id}.sort, sf.events_to_be_emitted(60).map {|e| e.id}.sort
      assert sf.to_be_shown?(60)
    else
      assert e.errors[:streaming_for]
    end
  end

  test "day events" do
    sf = stream_flows(:sf_one)
    current_event_with_streaming = documents(:current_event_with_streaming)
    # Lo convertimos en privado
    current_event_with_streaming.update_attribute(:published_at, nil)
    assert !sf.day_events.detect {|e| e.eql?(current_event_with_streaming)}, "Event current private event with streaming should not be in the day events list for sf_one because event is private"
    assert sf.day_events.detect {|e| e.eql?(documents(:event_with_streaming_and_sent_alert_and_show_in_irekia))}, "Event event_with_streaming_and_sent_alert_and_show_in_irekia should be in the day events list for sf_one."
    assert sf.day_events.detect {|e| e.eql?(documents(:event_with_streaming_en_diferido))}, "Event event_with_streaming_en_diferido should be in the day events list for sf_one."


    sf = stream_flows(:sf_two)
    assert !sf.day_events.empty?
    assert sf.day_events.detect {|e| e.eql?(documents(:event_with_streaming))}, "Event event_with_streaming should be in the day events list for sf_two."

  end

  test "assign event" do
    sf = StreamFlow.new(:title => 'Nueva sala')
    assert sf.event.nil?
    assert_nil sf.assign_event!
    assert sf.event.nil?


    sf = stream_flows(:sf_one)
    evt = documents(:private_event)
    evt.update_attribute(:streaming_for, 'irekia')
    assert sf.event.nil?
    assert_not_nil sf.assign_event!
    assert_equal sf.default_event, sf.event


    # Se emite en Irekia algo que no es un evento.
    sf.update_attributes(:show_in_irekia => true, :event_id => nil)
    sf.reload
    assert sf.event.nil?
    assert_nil sf.assign_event!
    # No se cambia el evento porque se está emitiendo
    assert sf.event.nil?

  end

  test "assign nil event if assigned events is not today event" do
    sf = stream_flows(:sf_one)
    evt = documents(:passed_event)
    sf.event = evt
    assert sf.save

    assert_equal evt, sf.event

    assert_nil sf.assign_event!
    assert_nil sf.event
  end

  test "streaming room photoxx" do
    sf = stream_flows(:sf_one)
    sf.photo = File.new(File.join(Document::MULTIMEDIA_PATH, "photos", "test.jpg"))
    assert sf.valid?
    assert sf.save

    assert_equal "test.jpg", sf.photo_file_name
    # En irekia3 cambiamos el tamaño de la foto de n320 a n600.
    assert_match "/uploads/streaming_rooms/#{sf.id}/n600/test.jpg", sf.photo_path

    sf.delete_photo = 1
    assert sf.save
    assert_nil sf.photo_file_name

  end

  test "send_alerts" do
    sf = StreamFlow.new(:title_es => 'Sala de streaming', :code => "xxx")
    assert sf.save
    assert sf.send_alerts?
  end

  test "programmed" do
    prog = StreamFlow.programmed

    assert_equal 3, prog.size
  end

  test "announced" do
    sf = stream_flows(:sf_one)

    assert sf.update_attributes(:announced_in_irekia => true)
    assert StreamFlow.announced.detect {|s| s.eql?(sf)}

    assert sf.update_attributes(:announced_in_irekia => false)
    assert_nil StreamFlow.announced.detect {|s| s.eql?(sf)}

  end


  test "live" do
    sf = stream_flows(:sf_one)
    assert sf.update_attributes(:show_in_irekia => true)
    assert StreamFlow.live.detect {|s| s.eql?(sf)}

    assert sf.update_attributes(:show_in_irekia => false)
    assert_nil StreamFlow.live.detect {|s| s.eql?(sf)}

  end

  test "status file" do
    sf = stream_flows(:sf_one)

    assert_equal "streaming#{sf.id}.txt", sf.status_file_name
  end

  test "traveling stream flow" do
    assert stream_flows(:sf_traveling).travelling?
    assert !stream_flows(:sf_one).travelling?
  end

 end
end
