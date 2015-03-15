require 'test_helper'

class SiteControllerTest < ActionController::TestCase
  
  def setup
    @request.cookies['locale'] = "es"
  end

  ['News', 'Event', 'Page', 'Album', 'Photo', 'Video'].each do |klass|    
    test "should send #{klass} to friend" do
      item = klass.constantize.first
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do  
        post :send_email, :sender_name => "Remitente", :recipient_name => "Receptor", :recipient_email => "receptor@efaber.net", :id => item.id, :t => klass
      end 
      assert_response :redirect

      m = ActionMailer::Base.deliveries.last
      assert_equal ['receptor@efaber.net'], m.to
      assert_equal I18n.t('share.te_recomienda', :sender_name => 'Remitente', :site_name => Settings.site_name), m.subject
    end
  end

  if Settings.optional_modules.proposals
    test "should send Proposal to friend" do
      item = Proposal.first
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do  
        post :send_email, :sender_name => "Remitente", :recipient_name => "Receptor", :recipient_email => "receptor@efaber.net", :id => item.id, :t => 'Proposal'
      end 
      assert_response :redirect

      m = ActionMailer::Base.deliveries.last
      assert_equal ['receptor@efaber.net'], m.to
      assert_equal I18n.t('share.te_recomienda', :sender_name => 'Remitente', :site_name => Settings.site_name), m.subject
    end
  end
  
  test "search should redirect to new methods" do
    get :search, :locale => 'es', :q => 'industria'
    assert_response :redirect
    assert_redirected_to get_create_search_index_path(:key => 'keyword', :value => 'industria', :new => true)
  end

  test "redirect to splash page if locale cookie is not set up" do
    @request.cookies['locale'] = nil
    get :show, :locale => nil
    assert_redirected_to lang_url
  end

  # test "consejo news should not be in iphone version" do
  #   get :show, :format => "iphone"
  #   assert assigns(:news).length > 0
  #   assert !assigns(:news).include?(documents(:consejo_news))
  # end
  
  test "should set uuid cookie" do
    get :show
    
    assert_not_nil cookies["openirekia_uuid"]
  end
  
  test "should show carousel news on home" do
    get :show
    assert_response :success
    assert assigns(:carousel_news)
    assert_nil assigns(:context)
    
    carousel_news = assigns(:carousel_news)
    
    # Comprobar el html de la lista
    assert_select 'div#home_leading_content div#news_carousel div.carousel-inner' do
      assert_select 'div.item', :count => carousel_news.length
      assert_select 'div.item div.featured_media div.featured_content div.title a', :text => carousel_news.first.title
    end
  end
  
 if Settings.optional_modules.debates and Settings.optional_modules.streaming
  test "should show link to current live streaming on home" do
    stream_flows(:sf_one).update_attribute(:show_in_irekia, true)
    get :show
    assert assigns(:streaming)
    assert assigns(:streaming).live.length == 1
    assert assigns(:streaming).live.first == stream_flows(:sf_one)
    assert_select 'div.upcoming_streamings' do
      assert_select 'div.title', :text => I18n.t('events.live_streaming')
      assert_select 'ul li.live div.streaming_info span.event_title a[href=?]', streaming_path(stream_flows(:sf_one)), :text => stream_flows(:sf_one).title
    end
  end
 end

 if Settings.optional_modules.debates
  test "should show carousel debates on home" do
    get :show
    assert_response :success
    assert assigns(:debates)

    # Comprobar el html de la lista
    assert_select 'div#debates_carousel div.carousel-inner' do
      assert_select 'div.item', :count => assigns(:debates).length
      assert_select 'div.item div.carousel-caption a', :text => assigns(:debates).first.title
    end
  end
 end

  test "should show snetworking" do
    get :snetworking
    assert_response :success
  end
  
  
  #
  # Enlaces en la home
  # ==================
  #
  # Los admin ven en la home el link "Tu irekia" y el link "Administración"
  # Para los políticos con permisos de gestión de los contenidos los enlaces son los mismos que para admin
  ["politician_interior", "admin"].each do |role|
    test "should show account and admin links for #{role} on home" do
      login_as(role)
      get :show
      assert_response :success
      
      assert_select 'li.nav_user_logged span.username a[href=?]', account_path # luego se le redirige a la administracion
      assert_select 'li.nav_settings ul.dropdown-menu li a[href=?]', admin_path
    end
  end

  # Los usuarios de irekia que getionan los contenidos ven en el navbar sólo el link "Administración"
  users = ["jefe_de_prensa", "miembro_que_modifica_noticias", "jefe_de_gabinete", "colaborador", "comentador_oficial", "secretaria_interior"]
  users << "operador_de_streaming" if Settings.optional_modules.streaming
  users.each do |role|
    test "should show only admin link for #{role} on home" do
      login_as(role)
      get :show
      assert_response :success
    
      assert_select 'li.nav_user_logged span.username a[href=?]', account_path # luego se le redirige a la administracion
      assert_select 'li.nav_settings ul.dropdown-menu li a[href=?]', admin_path
    end
  end
  
  # Los responsables de sala, no tienen ningún acceso especial
  test "should not show admin link for room manager" do
    login_as("room_manager")
    get :show
    assert_response :success
    assert_select 'li.nav_user_logged span.username a[href=?]', account_path # luego se le redirige a la administracion
    assert_select 'li.nav_settings ul.dropdown-menu li a[href=?]', admin_path, :count => 0
  end
    
  # Los ciudadanos y los políticos ven en el navbar sólo el enlace "Tú irekia"
  ["twitter_user", "facebook_user", "periodista", "visitante"].each do |role|
    test "should show only account link for #{role} on home" do
      login_as(role)
      get :show
      assert_response :success
    
      assert_select 'li.nav_user_logged span.username a[href=?]', account_path
      assert_select 'li.nav_settings ul.dropdown-menu li a[href=?]', admin_path, :count => 0
    end
  end
  
  ["politician_one", "politician_lehendakaritza"].each do |role|
    test "should show only politician show link for #{role} on home" do
      
      login_as(role)
      get :show
      assert_response :success
      
      assert_select 'li.nav_user_logged span.username a[href=?]', account_path
      assert_select 'li.nav_settings ul.dropdown-menu li a[href=?]', admin_path, :count => 0
      assert_select 'li.nav_settings ul.dropdown-menu li a[href=?]', politician_path(assigns(:current_user))
      
    end
  end
  
  test "should send email when filling contact form" do
    ActionMailer::Base.deliveries = []
    assert_difference 'ActionMailer::Base.deliveries.count', 1 do
      post :send_contact, {:name => "Groucho", :email => "groucho@example.com", :message => "This is my opinion. If you don't like it, I have another one."}
    end
    assert_select 'h1', I18n.t('site.contacto_enviado')
  end
  
  test "should not send email if contact information is incomplete" do
    ActionMailer::Base.deliveries = []
    assert_no_difference 'ActionMailer::Base.deliveries.count' do
      post :send_contact, {:name => "", :email => "", :message => ""}
    end
    assert assigns(:form_errors).collect {|e| e[0]}.sort.eql?(['email', 'message', 'name'])
    assert_select 'h1', I18n.t('site.contactar')
  end
  
  # test "should show warning to use optimized version when conecting from and iPhone" do
  #   @request.env['HTTP_USER_AGENT'] = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7"
  #   get :show
  #   assert_select 'p.mobile_warning', :text => "¿Usas iPhone? Consulta la versión optimizada"
  # end
  
  test "should show videos and fotos tabs" do
    get :show
    assert_select 'ul#photo_video_tabs' do
      assert_select 'li a', :text => "Vídeos"
      assert_select 'li a', :text => "Fotos"
    end
  end
  
  test "should show videos content" do
    get :show
    assert_select 'div.tab-content' do
      assert_select 'div#home_videos.tab-pane' do
        assert_select ' div.row-fluid div.grid_item.video', :count => 4
      end
    end
  end
  
  test "should show albums content" do
    get :show
    assert_select 'div.tab-content' do
      assert_select 'div#home_photos.tab-pane' do
        # This is commented because we don't have albums with photos in fixtures
        # assert_select ' div.row-fluid div.grid_item.album', :count => 4
      end
    end
  end

 context "corporative" do
   setup do
     @default_values = YAML::load_file(Corporative.file_name)
     @old_customized = @default_values.delete("customized")
     @old_site_name = @default_values["site_name"]
   end
   should "require admin" do
     put :update_setup, :corporative => @default_values.merge({:site_name => "Changed site name"})
     assert_response :redirect
     assert_equal I18n.t('no_tienes_permiso'), flash[:notice]
   end

   should "change corporative information" do
     login_as("admin")
     put :update_setup, :corporative => @default_values.merge({:site_name => "Changed site name"})
     assert_template "update_setup"
     assert_equal "Changed site name", YAML::load_file(Corporative.file_name)["site_name"]
   end

   teardown do
     # Restore previous value
     data = YAML::load_file(Corporative.file_name)
     data['site_name'] = @old_site_name
     data['customized'] = @old_customized
     File.open(Corporative.file_name, 'w') {|f| f.write data.to_yaml }
   end
 end
end

