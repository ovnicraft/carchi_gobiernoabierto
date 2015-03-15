require 'test_helper'

class BulletinMailerTest < ActionMailer::TestCase

  def setup
    ActionMailer::Base.deliveries = []
  end

  context "send bulletin copy" do
    setup do
      @bulletin_copy = bulletin_copies(:for_visitante)
      assert_difference 'ActionMailer::Base.deliveries.count', +1 do
        BulletinMailer.copy(@bulletin_copy).deliver
      end
      
      @email = ActionMailer::Base.deliveries.last
    end

    should "send bulletin to subscriber" do
      assert_equal [@bulletin_copy.user.email], @email.to
    end

    should "set correct subject" do
      # Test the body of the sent email contains what we expect it to
      # This journalist has requested alerts in spanish
      assert_equal "#{Bulletin.model_name.human}: #{@bulletin_copy.bulletin.title_es}", @email.subject
    end

    should "include links to bulletin copy news" do
      News.find(@bulletin_copy.news_ids).each do |news|
        assert_match news.title_es, @email.body.to_s
        assert_match I18n.l(news.published_at.to_date, :format => :long, :locale => 'es'), @email.body.to_s
      end
    end
  end

  should "respect user language preference" do
    bulletin_copy = bulletin_copies(:for_visitante)
    bulletin_copy.user.update_attribute(:alerts_locale, 'eu')
    # a copy is always delivered from an after save in bulletin_copy.rb which does this same locale change
    I18n.with_locale bulletin_copy.user.alerts_locale do
      email = BulletinMailer.copy(bulletin_copy).deliver
    end
    email = ActionMailer::Base.deliveries.last
    News.find(bulletin_copy.news_ids).each do |news|
      assert_match news.title_eu, email.body.to_s
      assert_match I18n.l(news.published_at.to_date, :format => :long, :locale => 'eu'), email.body.to_s
    end
  end

 if Settings.optional_modules.debates
  context "bulletin with debate" do
    setup do
      @bulletin_copy = bulletins(:with_debate).bulletin_copies.create(:user => users(:visitante))
    end
    should "include link to debate" do
      I18n.locale = :es
      email = BulletinMailer.copy(@bulletin_copy).deliver
      Debate.find(@bulletin_copy.debate_ids).each do |debate|
        assert_match debate.title_es, email.body.to_s
      end
    end
  end
 end
end
