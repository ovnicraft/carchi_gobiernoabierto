require 'test_helper'

class AccountControllerTest < ActionController::TestCase

  # ["politician_interior", "admin", "jefe_de_prensa", "miembro_que_modifica_noticias", "jefe_de_gabinete", "operador_de_streaming", "colaborador", "comentador_oficial", "secretaria_interior", "room_manager"].each do |role|
  ["politician_interior", "politician_one", "politician_lehendakaritza"].each do |role|
    test "#{role}'s account should redirect to politician page" do
      login_as(role)
      get :show
      assert_redirected_to politician_path(users(role.to_sym))
    end
  end


  roles = ["jefe_de_prensa", "miembro_que_modifica_noticias", "jefe_de_gabinete", "colaborador", "comentador_oficial", "secretaria_interior", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "#{role}'s account should redirect to administration" do
      login_as(role)
      get :show
      assert_redirected_to sadmin_account_path
    end
  end

  ["admin", "twitter_user", "facebook_user", "periodista", "visitante"].each do |role|
    test "#{role}'s account should show his profile" do
      login_as(role)
      get :show
      assert_response :success
      assert_template "show"
    end
  end


  test "account edit for secretaria de interior should redirect to admin" do
    login_as(:secretaria_interior)
    get :edit
    assert_redirected_to admin_path
  end

  ["twitter_user", "facebook_user"].each do |role|
    # TODO
    test "#{role} cannot view password edit link" do
      # login_as("twitter_user")
      # get :show
      # assert_response :success
      # assert_select "ul.edit_links li", :count => 2 do
      #   assert_select "a", :text => "Modificar mis datos"
      #   assert_select "a", :text => "Eliminar mi cuenta"
      #   assert_select "a", :text => "Modificar mi contraseña", :count => 0
      # end
    end

    test "#{role} can edit info" do
      login_as(role)
      get :edit
      assert_response :success
      assert_template "edit"
      assert_select "form[action=?]", '/es/account' do
        assert_select "input[name=?]", 'user[email]'
        assert_select "input[name=?]", 'user[name]'
        assert_select "input[name=?]", 'user[last_names]'
        assert_select "input[name=?]", 'user[password]', :count => 0
      end
    end

    test "#{role} cannot edit password" do
      login_as(role)
      get :pwd_edit
      assert_not_authorized
    end


    test "#{role} cannot update password" do
      login_as(role)
      put :pwd_update
      assert_not_authorized
    end
  end

  context "edit personal account" do
    ["periodista", "visitante", "politician_lehendakaritza"].each do |role|
      should "should edit account for #{role}" do
        login_as(role)
        get :edit
        assert_response :success
        assert_template "edit"
      end
    end

    roles = ["colaborador", "comentador_oficial", "secretaria_interior", \
     "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "room_manager", "admin", "politician_interior"]
    roles << "operador_de_streaming" if Settings.optional_modules.streaming
    roles.each do |role|
      should "should redirect to admin for #{role}" do
        login_as(role)
        get :edit
        assert_response :redirect
        assert_redirected_to admin_url
      end
    end
  end

  context "show personal account" do
    ["twitter_user", "facebook_user", "periodista", "visitante", "admin"].each do |role|
      should "should edit account for #{role}" do
        login_as(role)
        get :show
        assert_response :success
      end
    end

    ["politician_lehendakaritza", "politician_interior"].each do |role|
      should "redirect to politician show for #{role}" do
        login_as(role)
        get :show
        assert_response :redirect
        assert_redirected_to politician_path(assigns(:current_user))
      end
    end

    roles = ["colaborador", "comentador_oficial", "secretaria_interior", \
     "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "room_manager"]
    roles << "operador_de_streaming" if Settings.optional_modules.streaming
    roles.each do |role|
      should "should redirect to sadmin/account for #{role}" do
        login_as(role)
        get :show
        assert_response :redirect
        assert_redirected_to sadmin_account_url
      end
    end
  end


  roles = ["colaborador", "periodista", "visitante", "comentador_oficial", "secretaria_interior", \
     "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "room_manager", "twitter_user", "facebook_user"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
    test "#{role} can delete his account" do
      login_as(role)
      assert_no_difference 'User.count' do
        delete :destroy
      end
      assert_equal I18n.t('account.cuenta_eliminada'), flash[:notice]
      assert_redirected_to root_path
    end
  end

  context "periodista con alertas" do
    setup do
      login_as(:periodista_con_alertas)
    end

    should "view department subscription info" do
      get :edit
      assert_select 'input.depts'
    end

    should "be able to unsubscribe from all departments" do
      put :update, :user => {:subscriptions_attributes => Journalist.first.subscriptions.inject(Hash.new) {|h, s| h[s.id.to_s]= {"id" => s.id.to_s, "_destroy" => "1"}; h}}
      assert_response :redirect
    end

    should "should delete pending alerts when unsubscribing from a department" do
      # Una alerta es de lehendakaritza y la otra de gobierno vasco
      assert_equal 2, EventAlert.unsent.where(["spammable_id=? AND spammable_type='Journalist'", users("periodista_con_alertas").id]).count
      # quitamos lehendakaritza y dejamos gobierno vasco
      put :update, :user => {:subscriptions_attributes => {"0" => {"department_id" => organizations(:gobierno_vasco).id.to_s}, "1" => {"id" => subscriptions(:periodista_con_alertas4lehend).id.to_s, "_destroy" => "1"}}}
      assert_equal 1, EventAlert.unsent.where(["spammable_id=? AND spammable_type='Journalist'", users("periodista_con_alertas").id]).count
    end
  end

  test "activate user account" do
    user = users(:visitante_sin_activar)
    get :activate, :u => user.id, :p => user.crypted_password
    assert_response :success
    assert_template 'account/activate'
    assert_select "h1", :text => I18n.t('account.cuenta_activada')
  end

  test "do not activate user account invalid password" do
    user = users(:visitante_sin_activar)
    get :activate, :u => user.id, :p => "00742970dc9e6319f8019fd54864d3ea740f04b2"
    assert_response :success
    assert_template 'account/activate'
    assert_select "h1", :text => I18n.t('account.informacion_incorrecta')
  end

 if Settings.optional_modules.proposals
  context "my proposals" do
    setup do
      login_as('visitante')
      get :proposals
    end

    should "list approval pending and rejected proposals" do
      assert assigns(:proposals).include?(proposals(:unapproved_proposal))
      assert_equal 2, assigns(:proposals).pending.count
      assert_equal 1, assigns(:proposals).rejected.count
      assert_select 'li.proposal.not_moderated', :count => 3
      assert_select 'li.proposal.rejected', :count => 1
    end
  end
 end

  context "floki activity" do
    setup do
      login_as('visitante')
      get :activity, :format => "floki"
    end

    should "respond successfully" do
      assert_response :success
      assert_template 'activity.json'
      @output = JSON.parse(@response.body)
    end

   if Settings.optional_modules.proposals
    context "fetched_content" do
      setup do
        @output = JSON.parse(@response.body)

        @response_titles = @output["items"].collect {|item| item['title']}
      end

      should "show votes to my proposals" do
        assert assigns(:my_content).include?(votes(:one))
        value = votes(:one).value
        @response_titles.include?(I18n.t('floki.activity.vote_for', :value => (value == -1 ? I18n.t('proposals.against') : I18n.t('proposals.in_favor')), :title => votes(:one).votable.title))
      end
    end
   end
  end

end
