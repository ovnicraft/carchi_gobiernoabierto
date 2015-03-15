require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  test "should delete pending alerts if subscription is cancelled" do
    user = users(:periodista_con_alertas)
    # Esto no funciona porque en la condicion pone "spammable_type='User'" en lugar de "spammable_type='Journalist'"
    # user.event_alerts
    assert_equal 1, EventAlert.sent.where(["spammable_id=? AND spammable_type='Journalist'", user.id]).count
    assert_equal 2, EventAlert.unsent.where(["spammable_id=? AND spammable_type='Journalist'", user.id]).count
    assert_difference 'Subscription.count', -1 do
      subscriptions(:periodista_con_alertas4lehend).destroy
    end
    assert_equal 1, EventAlert.sent.where(["spammable_id=? AND spammable_type='Journalist'", user.id]).count
    assert_equal 1, EventAlert.unsent.where(["spammable_id=? AND spammable_type='Journalist'", user.id]).count
  end
end
