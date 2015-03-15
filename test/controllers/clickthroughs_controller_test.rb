require 'test_helper'

class ClickthroughsControllerTest < ActionController::TestCase
  test "valid clickthrough info redirect to content" do
    assert_difference 'Clickthrough.count', +1 do
      get :track, :id => @controller.encode_clickthrough(bulletin_copies(:for_visitante), documents(:one_news))
    end
    assert_redirected_to news_url(documents(:one_news))
  end
  
  test "invalid clickthrough info raises RecordNotFound" do
    assert_no_difference 'Clickthrough.count' do
      get :track, :id => "sdfadf"
    end
    # assert_raise ActiveRecord::RecordNotFound # we have rescue_from
    assert :template => "/site/notfound"
  end

 if Settings.optional_modules.debates
  test "clickthrough from bulletin to debate" do
    assert_difference 'Clickthrough.count', +1 do
      get :track, :id => @controller.encode_clickthrough(bulletin_copies(:for_visitante), debates(:debate_completo))
    end
    assert_redirected_to debate_url(debates(:debate_completo))
  end
 end
end
