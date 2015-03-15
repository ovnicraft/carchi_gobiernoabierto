require 'test_helper'
include ERB::Util

class UsersHelperTest < ActionView::TestCase
  # include ActionView::Helpers::UrlHelper
  # include ActionController::UrlWriter

  def setup
    ActionController::Base.default_url_options = { locale: I18n.locale }
  end

  ['visitante', 'periodista'].each do |role|
    test "link to #{role} profile" do
      tag = link_to_user_profile_unless_deleted(users(role.to_sym))
      assert_match user_path(users(role.to_sym)), tag
    end
  end

  test "link to politician profile" do
    tag = link_to_user_profile_unless_deleted(users(:politician_one))
    assert_match politician_path(users(:politician_one)), tag
  end

  users = ["deleted_person", "admin", "colaborador", "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "comentador_oficial", "secretaria_interior", "room_manager"]
  users << 'operador_de_streaming' if Settings.optional_modules.streaming
  users.each do |role|
    test "link to #{role} profile" do
      tag = link_to_user_profile_unless_deleted(users(role.to_sym))
      assert_equal tag, users(role.to_sym).public_name
    end
  end
end
