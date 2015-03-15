require 'test_helper'

class Admin::StreamFlowsControllerTest < ActionController::TestCase
 if Settings.optional_modules.streaming
  def setup
    UserActionObserver.current_user = users(:admin).id
  end

  test "unlogged user should not be redirected" do
    get :index
    assert_not_authorized
  end

  ["admin", "operador_de_streaming", "colaborador"].each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :index
      assert_response :success
      assert_template "list"
    end
  end

  ["periodista", "visitante", "comentador_oficial", "secretaria_interior",  \
   "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "room_manager"].each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :index
       assert_not_authorized
     end
  end

  test "admin sees the flows list" do
    login_as("admin")

    get :list
    assert_response :success

    assert assigns(:stream_flows)
    assert_equal StreamFlow.count, assigns(:stream_flows).compact.size
    assert_nil assigns(:stream_flows).last
    assert_select 'div.special_options a', /Ordenar/
  end


  test "streaming operator sees the flows index" do
    login_as("operador_de_streaming")

    get :index
    assert_response :success

    assert assigns(:stream_flows)
    assert_equal StreamFlow.programmed.size, assigns(:stream_flows).size
  end

  test "streaming operator sees the flows list" do
    login_as("operador_de_streaming")

    get :list
    assert_response :success

    assert assigns(:stream_flows)
    assert_equal StreamFlow.count, assigns(:stream_flows).compact.size
    assert_nil assigns(:stream_flows).last
    assert_select 'div.special_options', :count => 0
  end

  test "streaming operator cannot modify streamings" do
    login_as("operador_de_streaming")
    get :edit, :id => stream_flows(:sf_one).id
    assert_not_authorized

    get :new, :id => stream_flows(:sf_one).id
    assert_not_authorized

    assert_no_difference('StreamFlow.count') do
      post :create, :stream_flow => {:title_es => "Stream de prueba", :code => "prueba.sdp" }
    end
    assert_not_authorized

    put :update, :id => stream_flows(:sf_one).id
    assert_not_authorized
  end


  test "should get new" do
    login_as(:admin)
    get :new
    assert_response :success
  end

  test "should create stream_flow" do
    login_as(:admin)
    assert_difference('StreamFlow.count') do
      post :create, :stream_flow => {:title_es => "Stream de prueba", :code => "prueba.sdp" }
    end

    assert_redirected_to admin_stream_flows_path()
  end

  test "should get edit" do
    login_as(:admin)
    get :edit, :id => stream_flows(:sf_one).id
    assert_response :success
    assert_not_nil assigns(:stream_flow)

    assert_select "input#stream_flow_title_es"
    assert_select "input#stream_flow_title_eu"
    assert_select "input#stream_flow_title_en"
    assert_select "input#stream_flow_code"
    assert_select "input#stream_flow_send_alerts"
    assert_select "input#stream_flow_photo"

    assert_select "input#return_to"
  end

  test "should update stream_flow" do
    login_as(:admin)
    put :update, :id => stream_flows(:sf_one).id, :stream_flow => {:title_es => "Nuevo título", :code => "nuevo.sdp",
      :photo => Rack::Test::UploadedFile.new(File.join(Document::MULTIMEDIA_PATH, "photos", "test.jpg"), "image/jpg"), :send_alerts => false }
    assert_redirected_to admin_stream_flows_path()

    assert_equal "test.jpg", assigns(:stream_flow).photo_file_name
    assert !assigns(:stream_flow).send_alerts?

    # clean test assets
    dirname = File.dirname(assigns(:stream_flow).photo.path).split('/')[0..-1].join('/')
    assert FileUtils.rm_rf(File.dirname(dirname))
  end

  test "should update stream_flow and redirect to streamings' list" do
    login_as(:admin)
    put :update, :id => stream_flows(:sf_one).id, :stream_flow => {:title_es => "Nuevo título",
        :code => "nuevo.sdp", :photo => Rack::Test::UploadedFile.new(File.join(Document::MULTIMEDIA_PATH, "photos", "test.jpg"), "image/jpg"), :send_alerts => false },
      :return_to => list_admin_stream_flows_path()
    assert_redirected_to list_admin_stream_flows_path()

    assert_equal "test.jpg", assigns(:stream_flow).photo_file_name
    assert !assigns(:stream_flow).send_alerts?
    # clean test assets
    dirname = File.dirname(assigns(:stream_flow).photo.path).split('/')[0..-1].join('/')
    assert FileUtils.rm_rf(File.dirname(dirname))
  end

  test "should destroy stream_flow" do
    login_as(:admin)
    assert_difference('StreamFlow.count', -1) do
      delete :destroy, :id => stream_flows(:sf_one).id
    end

    assert_redirected_to admin_stream_flows_path
  end

  test "streaming operator cannot edit stream flow name" do
    login_as("operador_de_streaming")
    get :edit, :id => stream_flows(:sf_one).id
    assert_not_authorized
  end

  test "streaming operator sees room manager tab" do
    login_as("operador_de_streaming")
    get :index
    assert_response :success
    assert_select 'div.one_news_submenu ul li', :count => 3
    assert_select 'div.one_news_submenu ul li a', 'Eventos programados'
    assert_select 'div.one_news_submenu ul li a', 'Flujos'
    assert_select 'div.one_news_submenu ul li a', 'Responsables de sala'
  end

  test "should show announce buttons" do
    flow = stream_flows(:sf_two)

    login_as("admin")
    get :index
    assert_response :success

    assert assigns(:stream_flows)
    assert assigns(:stream_flows).include?(stream_flows(:sf_one)), "Stream flow sf_one should be in the list of programmed streamings"
    assert assigns(:stream_flows).include?(stream_flows(:sf_two)), "Stream flow sf_two should be in the list of programmed streamings"
    assert assigns(:stream_flows).include?(stream_flows(:sf_without_alerts)), "Stream flow sf_without_alerts should be in the list of programmed streamings"
    assert_equal 3, assigns(:stream_flows).size

    assert_select 'table.flows' do
      assert_select 'tr', :count => 1 do
        assert_select "td", :count => 3

        assert_select "td#td_#{flow.id}" do
          assert_select 'div.streaming_status' do
            assert_select 'div.irekia_row' do
              assert_select "input#show_in_irekia_#{flow.id}"
              assert_select "input#hide_in_irekia_#{flow.id}"
              assert_select "div.web_and_announcement" do
                assert_select "input#announce_in_irekia_#{flow.id}"
                assert_select "input#hide_announcement_in_irekia_#{flow.id}"
              end
            end
          end
        end
      end
    end
  end

  test "should show announce buttons if event is null but day events is not empty" do
    flow = stream_flows(:sf_two)
    assert_nil flow.event
    assert !flow.day_events.empty?, "El streaming sf_two tiene que tener eventos del día"
    assert_not_nil flow.default_event

    login_as("admin")
    get :index
    assert_response :success

    assert assigns(:stream_flows)
    assert_equal 3, assigns(:stream_flows).size


    assert_select 'table.flows' do
      assert_select 'tr', :count => 1 do
        assert_select "td", :count => 3

        assert_select "td#td_#{flow.id}" do
          assert_select 'div.streaming_status' do
            assert_select 'div.irekia_row' do
              assert_select "input#show_in_irekia_#{flow.id}"
              assert_select "input#hide_in_irekia_#{flow.id}"
              assert_select "div.web_and_announcement" do
                assert_select "input#announce_in_irekia_#{flow.id}"
                assert_select "input#hide_announcement_in_irekia_#{flow.id}"
              end
            end
          end
        end
      end
    end
  end


  test "should announce streaming" do
    login_as("operador_de_streaming")
    sf = stream_flows(:sf_one)
    assert !sf.announced_in_irekia?

    sf2 = stream_flows(:sf_two)
    sf2.update_attribute(:announced_in_irekia, true)
    sf2.reload
    assert sf2.announced_in_irekia?

    post :update_status, :id => sf.id, :announce_irekia_on => "Anunciar", :stream_flow => {:event_id => nil}
    assert_response :redirect

    assert File.exists?(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    assert_match "announce_irekia_on", File.read(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))

    # El que acabamos de  anunciar ya está anunciado
    sf.reload
    assert sf.announced_in_irekia?

    # El que estaba anunciado sigue
    sf2.reload
    assert sf2.announced_in_irekia?

    # Limpieza
    File.delete(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    File.delete(sf.event_info_file_path)
  end

  test "should hide announcement" do
    login_as("operador_de_streaming")
    sf = stream_flows(:sf_one)
    sf.update_attribute(:announced_in_irekia, true)
    assert sf.announced_in_irekia?

    post :update_status, :id => sf.id, :announce_irekia_off => "Defar de anunciar", :stream_flow => {:event_id => nil}
    assert_response :redirect

    sf.reload
    assert !sf.announced_in_irekia?

    # Limpieza
    File.delete(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    File.delete(sf.event_info_file_path)
  end

  test "should show streaming" do
    login_as("operador_de_streaming")
    sf = stream_flows(:sf_one)
    assert !sf.show_in_irekia?

    sf2 = stream_flows(:sf_two)
    sf2.update_attribute(:show_in_irekia, true)
    sf2.reload
    assert sf2.show_in_irekia?

    post :update_status, :id => sf.id, :show_irekia_on => "Empezar a emitir", :stream_flow => {:event_id => nil}
    assert_response :redirect

    assert File.exists?(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    assert_match "show_irekia_on event:", File.read(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))

    assert File.exists?(sf.event_info_file_path)
    info_txt = File.read(sf.event_info_file_path)
    assert_match /^\s*$/, info_txt

    sf.reload
    assert sf.show_in_irekia?

    # No se deja de emitir automáticamente porque puedes coincidir varias emisiones a la vez.
    sf2.reload
    assert sf2.show_in_irekia?

    # Limpieza
    File.delete(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    File.delete(sf.event_info_file_path)
  end

  test "should show event streaming" do
    login_as("operador_de_streaming")
    sf = stream_flows(:sf_two)
    assert !sf.show_in_irekia?


    post :update_status, :id => sf.id, :show_irekia_on => "Empezar a emitir", :stream_flow => {:event_id => documents(:event_with_streaming).id}
    assert_response :redirect

    assert_equal documents(:event_with_streaming), assigns(:stream_flow).event

    assert File.exists?(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    assert_match "show_irekia_on event:#{documents(:event_with_streaming).id}", File.read(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))

    assert File.exists?(sf.event_info_file_path)
    event_info = File.read(sf.event_info_file_path)
        assert_match documents(:event_with_streaming).title, event_info
        assert_match "div id='event_es'", event_info
        assert_match "div id='event_eu'", event_info
        assert_match "div id='event_en'", event_info

        assert_match "<span class=\"event_title\"><a href=\"/es/events", event_info

    sf.reload
    assert sf.show_in_irekia?

    # Limpieza
    File.delete(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    File.delete(sf.event_info_file_path)
  end


  test "should show announced streaming" do
    login_as("operador_de_streaming")
    sf = stream_flows(:sf_one)
    event = documents(:event_with_streaming)
    sf.event = event
    sf.announced_in_irekia = true
    assert sf.save
    sf.reload
    assert sf.announced_in_irekia?
    assert !sf.show_in_irekia?
    assert_equal event, sf.event

    sf2 = stream_flows(:sf_two)
    assert !sf2.announced_in_irekia?
    assert !sf2.show_in_irekia?

    post :update_status, :id => sf.id, :show_irekia_on => "Empezar a emitir"
    assert_response :redirect

    sf.reload
    assert_equal event, sf.event
    assert !sf.announced_in_irekia?
    assert sf.show_in_irekia?

    sf2.reload
    assert !sf2.announced_in_irekia?
    assert !sf2.show_in_irekia?

    # Limpieza
    File.delete(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    File.delete(sf.event_info_file_path)

  end

  test "should show streaming different from the announced one" do
    login_as("operador_de_streaming")
    sf = stream_flows(:sf_one)
    sf.update_attribute(:announced_in_irekia, true)
    sf.reload
    assert sf.announced_in_irekia?
    assert !sf.show_in_irekia?

    sf2 = stream_flows(:sf_two)
    assert !sf2.announced_in_irekia?
    assert !sf2.show_in_irekia?

    post :update_status, :id => sf2.id, :show_irekia_on => "Empezar a emitir", :stream_flow => {:event_id => nil}
    assert_response :redirect
    assert assigns(:show_checked)

    # El streaming sf sigue como estaba.
    sf.reload
    assert sf.announced_in_irekia?
    assert !sf.show_in_irekia?

    # El streaming s2 cambia de estado.
    sf2.reload
    assert !sf2.announced_in_irekia?
    assert sf2.show_in_irekia?

    # Limpieza
    File.delete(File.join(Rails.root, "/public/streaming_status", "streaming#{sf2.id}.txt"))
    File.delete(sf2.event_info_file_path)

  end

  test "shoud unset event when streaming has finished" do
    login_as("operador_de_streaming")
    sf = stream_flows(:sf_one)
    assert_not_nil sf.assign_event!
    sf.update_attribute(:show_in_irekia, true)
    assert sf.on_web?

    post :update_status, :id => sf.id, :show_irekia_off => "Dejar de emitir", :stream_flow => {:event_id => nil}
    assert_response :redirect
    assert !assigns(:show_checked)

    sf.reload
    assert !sf.on_web?
    assert_nil sf.event

    # Limpieza
    File.delete(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    File.delete(sf.event_info_file_path)

  end

  test "streaming operator sees the flows index with no event assigned" do
    sf = stream_flows(:sf_one)
    event = documents(:event_with_streaming_en_diferido)

    assert_equal sf.id, event.stream_flow_id
    assert_nil sf.event

    login_as("operador_de_streaming")

    get :index
    assert_response :success

    assert assigns(:stream_flows)

    assert_select "td#td_#{sf.id}" do
      assert_select "form#sf_#{sf.id}_status_form" do
        assert_select "ul.event_radio" do
          # assert_select "input#stream_flow_event_id_#{event.id}[type=radio][checked=checked]"
          assert_select "input#stream_flow_event_id_#{event.id}[type=radio]"
          assert_select "input#stream_flow_event_id[type=radio]"
        end
      end
    end

  end

  # Special cases

  test "streaming operator sees the flows index with old event assigned" do
    sf = stream_flows(:sf_one)
    event = documents(:event_with_streaming_en_diferido)

    assert_equal sf.id, event.stream_flow_id
    assert_nil sf.event

    # Assignamos un evento viejo
    sf.event = documents(:passed_event)
    assert sf.save
    assert_equal documents(:passed_event), sf.event

    login_as("operador_de_streaming")

    get :index
    assert_response :success

    assert assigns(:stream_flows)

    # Si hay un evento asignado que no sale en la lista de eventos, ninguno de los radio está seleccionado
    assert_select "td#td_#{sf.id}" do
      assert_select "form#sf_#{sf.id}_status_form" do
        assert_select "ul.event_radio" do
          assert_select "input#stream_flow_event_id_#{event.id}[type=radio][checked=true]", :count => 0
          assert_select "input#stream_flow_event_id_#{event.id}[type=radio]"
          assert_select "input#stream_flow_event_id[type=radio]"
        end
      end
    end

    # Al empezar a emitir, se borra el evento asignado al stream flow.
    post :update_status, :id => sf.id, :show_irekia_on => "Empezar a emitir"
    assert_response :redirect

    sf.reload
    assert_nil sf.event

    # Limpieza
    File.delete(File.join(Rails.root, "/public/streaming_status", "streaming#{sf.id}.txt"))
    File.delete(sf.event_info_file_path)
  end

 end
end
