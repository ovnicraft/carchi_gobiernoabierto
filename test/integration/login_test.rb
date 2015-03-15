require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest
  fixtures :all

  profiles = {"superadmin" => "sadmin_news_index_path", "colaborador"=> "sadmin_news_index_path", 
   "jefe_de_prensa" => "sadmin_news_index_path", "jefe_de_gabinete" => "sadmin_events_path", 
   "secretaria_interior" => "sadmin_events_path", 
   "visitante" => "account_path", "periodista" => "account_path", "room_manager" => "sadmin_account_path"}
  profiles["operador_de_streaming"] = "admin_stream_flows_path" if Settings.optional_modules.streaming

  profiles.each do |role, url|
    test "#{role} login ends up in #{url}" do
      get_via_redirect "/es/login"
      assert_response :success

      user = users(role)
      post_via_redirect session_path, :email => user.email, :password => 'test'
      assert_equal eval(url), path
    end
  end

end
