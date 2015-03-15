require 'test_helper'

class RelatedEventTest < ActiveSupport::TestCase
  
  test "read" do
    assert_equal documents(:passed_event), related_events(:rel_video_passed_event).event
    assert_equal videos(:featured_video), related_events(:rel_video_passed_event).eventable

    assert_equal documents(:emakunde_passed_event), related_events(:rel_news_event).event
    assert_equal documents(:news_with_event), related_events(:rel_news_event).eventable

  end
  
end
