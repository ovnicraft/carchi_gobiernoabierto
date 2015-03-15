require 'test_helper'

class BulletinCopyTest < ActiveSupport::TestCase

  context "create copy" do
    setup do
      @bulletin = bulletins(:one_hour_ago)
      ActionMailer::Base.deliveries = []
    end

    should "send copy by email" do
      # TODO: review this when ActionMailer is reviewed
      assert_difference 'ActionMailer::Base.deliveries.count', +1 do
        @bulletin_copy = @bulletin.bulletin_copies.create(:user => users(:visitante))
      end

      email = ActionMailer::Base.deliveries.last

      assert_equal [@bulletin_copy.user.email], email.to
      assert_equal "#{Bulletin.model_name.human}: #{@bulletin_copy.bulletin.title_es}", email.subject
    end

    # context "on error sending email" do
    #   setup do
    #     # TODO mock action mailer failure
    #     BulletinMailer.expects(:deliver).returns(false)
    #     @bulletin_copy = @bulletin.bulletin_copies.create(:user => users(:visitante))
    #   end
    #
    #   should "destroy bulletin_copy object" do
    #     # TODO assert @bulletin_copy.reload ???
    #     assert ActionMailer::Base.deliveries.count > 0
    #   end
    # end

    should "populate news_ids" do
      @bulletin_copy = @bulletin.bulletin_copies.create(:user => users(:visitante))
      assert !@bulletin_copy.news_ids.blank?
    end

  end

  context "with news featured for bulletin" do
    setup do
      @bulletin = Bulletin.create(:featured_news_ids => [documents(:one_news).id, documents(:featured_news).id])
      @copy = @bulletin.bulletin_copies.create!(:user_id => users(:visitante).id)
    end

    should "copy should include featured news" do
      assert_equal [documents(:one_news).id, documents(:featured_news).id].sort, @copy.ordered_featured_news.collect(&:id).sort
    end

    should "not include featured news in user news block" do
      assert_equal [],  @copy.ordered_featured_news & @copy.ordered_user_news
    end
  end
  
  should "not send news sent in previous bulletin" do
    copy = users(:visitante).bulletin_copies.create(:bulletin => Bulletin.create)
    assert copy.news_ids.include?(documents(:published_news).id) # includes this news because is the last published

    copy2 = users(:visitante).bulletin_copies.create(:bulletin => Bulletin.create)
    assert !copy2.news_ids.include?(documents(:published_news).id)
  end

  should "not include consejo news" do
    copy = users(:visitante).bulletin_copies.create(:bulletin => Bulletin.create)
    assert !copy.news_ids.include?(documents(:consejo_news).id) 
  end
end
