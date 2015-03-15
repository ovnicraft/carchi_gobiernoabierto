require 'test_helper'

class CommentTest < ActiveSupport::TestCase

  def default_fields
    {:commentable => documents(:commentable_news), :user => users(:visitante), :body => "Este artículo es muy interesante"}
  end

  [:user, :body].each do |field|
    test "should not save without #{field}" do
      comment = Comment.new(default_fields.merge(field => nil))
      assert !comment.save
      assert comment.errors[field.to_sym].include?("no puede estar vacío")
    end
  end

  user_types = %w(superadmin admin periodista visitante colaborador jefe_de_prensa jefe_de_gabinete secretaria comentador_oficial miembro_que_crea_noticias)
  user_types << "operador_de_streaming" if Settings.optional_modules.streaming
  user_types.each do |user|
    test "comments made by #{user} should not have empty email" do
      comment = Comment.new({:commentable => documents(:commentable_news), :user => users(user), :body => "Este artículo es muy interesante", :email => nil})
      # Gets saved because there is a before_validation that fixes the empty email
      assert comment.save
      assert_equal users(user).email, comment.email
    end
  end

  test "twitter_user should be able to make a comment without email" do
    comment = Comment.new :user => users(:twitter_user), :commentable => documents(:commentable_news), :body => "Este artículo es muy interesante"
    assert comment.save
    assert_nil comment.email
  end

  test "facebook_user should be able to make a comment without email" do
    comment = Comment.new :user => users(:facebook_user), :commentable => documents(:commentable_news), :body => "Este artículo es muy interesante"
    assert comment.save
    assert_nil comment.email
  end

  test "assign language to comment" do
    comment = Comment.new(default_fields)
    assert comment.save
    assert_not_nil comment.locale
  end

  [:visitante, :periodista, :colaborador].each do |user|
    test "#{user} comments have pending status" do
      comment = Comment.new(default_fields.merge(:user => users(user)))
      assert comment.save
      assert comment.status.eql?("pendiente")
    end
  end

  [:admin, :jefe_de_prensa, :jefe_de_gabinete].each do |user|
    test "#{user} comments have approved status" do
      comment = Comment.new(default_fields.merge(:user => users(user)))
      assert comment.save
      assert comment.status.eql?("aprobado")
    end
  end

  test "parent area is assigned when creating comment" do
    comment = Comment.create(default_fields)
    assert_equal comment.tag_list, documents(:commentable_news).area_tags
  end

  test "parent area is assigned when creating external comment on irekia news" do
    external_item = external_comments_items(:euskadinet_item_commentable_irekia_news)
    irekia_news = external_item.irekia_news

    comment = Comment.create(default_fields.merge({:commentable => external_item}))
    assert_equal irekia_news.area_tags, comment.tag_list
  end

  test "parent area is not assigned when creating external comment on external page" do
    external_item = external_comments_items(:euskadinet_item1)
    assert_nil external_item.irekia_news

    comment = Comment.create(default_fields.merge({:commentable => external_item}))
    assert_equal [], comment.tag_list
  end

  context "notifications" do
    should "not create notification for unapproved comment in news" do
      assert_no_difference 'Notification.count' do
        comment = Comment.create(default_fields)
      end
    end

    should "not create notification approved comment in news" do
      assert_no_difference 'Notification.count' do
        comment = Comment.create(default_fields.merge({:status => "aprobado"}))
      end
    end

   if Settings.optional_modules.proposals
    should "not create notification for unapproved comment in unapproved proposal" do
      assert_no_difference 'Notification.count' do
        comment = proposals(:unapproved_proposal).comments.create(:user => users(:visitante), :body => "Este artículo es muy interesante")
      end
    end

    should "not create notification for approved comment in unapproved proposal" do
      assert_no_difference 'Notification.count' do
        comment = proposals(:unapproved_proposal).comments.create(:user => users(:visitante), :body => "Este artículo es muy interesante", :status => "aprobado")
      end
    end

    should "not create notification for unapproved comment in approved proposal" do
      assert_no_difference 'Notification.count' do
        comment = proposals(:approved_and_published_proposal).comments.create(:user => users(:visitante), :body => "Este artículo es muy interesante")
      end
    end

    should "create notification for approved comment in approved proposal" do
      comment = proposals(:approved_and_published_proposal).comments.create(:user => users(:visitante), :body => "Este artículo es muy interesante")
      assert_difference 'Notification.count', +1 do
        comment.update_attributes(:status => "aprobado")
      end
    end

    context "official comment in proposal" do
      setup do
        @proposal = FactoryGirl.create(:published_and_approved_proposal)
        @comment = FactoryGirl.create(:official_comment_on_proposal, commentable: @proposal)
      end

      should "set comment as official" do
        assert @comment.is_official?
      end

    end

   end
  end

  context "emails about official comments" do
    setup do
      ActionMailer::Base.deliveries = []
    end

   if Settings.optional_modules.proposals
    context "in proposals" do
      setup do
        assert ActionMailer::Base.deliveries.empty?
        comment = proposals(:approved_and_published_proposal).comments.create(:user => users(:comentador_oficial), :body => "Este artículo es muy interesante")
        @sent_emails = ActionMailer::Base.deliveries
      end

      should "create email for proposal creator" do
        assert_equal 1, @sent_emails.length
        assert_match I18n.t('notifier.proposal_answer.subject', :site_name => Settings.site_name), @sent_emails.first.subject
        assert_equal [proposals(:approved_and_published_proposal).author.email], @sent_emails.first.to
      end

      should "not create email for that same comment author even if he's in previous commenters list" do
        assert proposals(:approved_and_published_proposal).commenters.include?(users(:comentador_oficial))
        assert (@sent_emails.collect(&:to).flatten & [users(:comentador_oficial).email]).empty?
      end
    end

    context "in proposal with argument" do
      setup do
        assert ActionMailer::Base.deliveries.empty?
        comment = proposals(:interior_proposal).comments.create(:user => users(:comentador_oficial), :body => "Este artículo es muy interesante")
        @sent_emails = ActionMailer::Base.deliveries
      end

      should "create email for previous argumenters" do
        assert_equal 1, @sent_emails.length
        assert_match I18n.t('notifier.proposal_answer.subject', :site_name => Settings.site_name), @sent_emails.first.subject
        assert_equal [proposals(:interior_proposal).argumenters.first.email], @sent_emails.first.to
      end

    end

    should "not create email for non official comment in proposal" do
      assert_no_difference 'ActionMailer::Base.deliveries.count' do
        comment = proposals(:approved_and_published_proposal).comments.create(:user => users(:visitante), :body => "Este artículo es muy interesante")
      end
    end
   end

   if Settings.optional_modules.debates
    context "in debate" do
      setup do
        assert ActionMailer::Base.deliveries.empty?
        comment = debates(:debate_completo).comments.create(:user => users(:comentador_oficial), :body => "Este artículo es muy interesante")
        @sent_emails = ActionMailer::Base.deliveries
      end

      should "create email for previous argumenters" do
        assert_equal 1, @sent_emails.length
        assert_equal "#{I18n.t('notifier.comment_answer.subject', site_name: Settings.site_name, locale: 'eu')} / #{I18n.t('notifier.comment_answer.subject', site_name: Settings.site_name, locale: 'es')}", @sent_emails.first.subject
        assert_equal [debates(:debate_completo).argumenters.first.email], @sent_emails.first.to
      end
    end
   end

    context "in any content other than proposal" do
      setup do
        assert ActionMailer::Base.deliveries.empty?
        comment = documents(:commentable_news).comments.create(:user => users(:comentador_oficial), :body => "Este artículo es muy interesante")
        @sent_emails = ActionMailer::Base.deliveries
      end

      should "create email for previous commenters" do
        assert_equal 1, ActionMailer::Base.deliveries.count
        assert_equal [users(:visitante).email], @sent_emails.first.to
      end

      should "not create email for that same comment author even if he's in previous commenters list" do
        assert documents(:commentable_news).commenters.include?(users(:comentador_oficial))
        assert (@sent_emails.collect(&:to).flatten & [users(:comentador_oficial).email]).empty?
      end
    end

  end

  context "external comments" do
    setup do
      @commentable = external_comments_items(:euskadinet_item1)
    end

    should "save comment" do
      comment = Comment.new(:commentable => @commentable, :user => users(:visitante), :body => "Este artículo es muy interesante")
      assert comment.save
    end
  end


  context "in department" do
    setup do
      @department = organizations(:lehendakaritza)
      @organization_ids = [@department.id] + @department.organization_ids
      @client_ids = ExternalComments::Client.where({:organization_id => @organization_ids}).map {|client| client.id}
    end

    should "get comments on documents belonging to department" do
      department_comments = Comment.in_organizations(@organization_ids)

      department_comments.each do |comment|
        assert comment.commentable.department.eql?(@department)
      end
    end

    should "get comments on external pages belonging to department" do
      department_comments = Comment.in_clients(@client_ids)

      department_comments.each do |comment|
        assert comment.commentable.department.eql?(@department)
      end
    end


    should "get comments on documents and external items belonging to department" do
      department_comments = Comment.in_organizations_and_clients(@organization_ids, @client_ids)

      department_comments.each do |comment|
        assert comment.commentable.department.eql?(@department)
      end
    end
  end

  context "stats_counters" do
    should "news without stats entry create and populate stats" do
      news = documents(:commentable_news)
      comment = FactoryGirl.create(:comment_on_news, :commentable => news)
      assert_comment_counters(comment.commentable)
    end

    comment_types = %w(comment_on_news official_comment_on_news comment_on_event official_comment_on_event comment_on_video comment_on_external_item )
    comment_types += %w(comment_on_proposal official_comment_on_proposal) if Settings.optional_modules.proposals
    comment_types += %w(comment_on_debate official_comment_on_debate) if Settings.optional_modules.debates
    comment_types.each do |comment_type|
      context "#{comment_type} comment" do
        setup do
          @comment = FactoryGirl.build(comment_type.to_sym)
          @comment.save
        end

        should "update counters when creating a new comment" do
          assert_comment_counters(@comment.commentable)
        end

        should "update counters when deleting a comment" do
          @comment.destroy
          assert_comment_counters(@comment.commentable)
        end

        should "update counters when approving an argument" do
          @comment.approve!
          assert_comment_counters(@comment.commentable)
        end
      end
    end

   if Settings.optional_modules.proposals
    context "additional stats_counters for proposal answers" do
      setup do
        @proposal = FactoryGirl.create(:published_and_approved_proposal, :published_at => 1.hour.ago)
        @official_response = FactoryGirl.create(:official_comment_on_proposal, :commentable => @proposal)
      end

      should "populate answer_time column in stats table" do
        assert_equal (@official_response.created_at - @proposal.published_at).to_i, @proposal.stats_counter.answer_time_in_seconds
      end
    end
   end

    # context "external comments" do
    #   should "external comments" do
    #     skip("make tests for external comments statistics")
    #   end
    # end
  end

  context "akismet" do
    setup do
      @comment = Comment.new(default_fields)
    end

    should "mark as spam if Akismet returns true" do
      FakeWeb.register_uri(:post, 'http://myakismetkey.rest.akismet.com/1.1/comment-check', :body => 'true')
      assert @comment.save
      assert @comment.spam?
    end

    should "mark as pending if Akismet returns false" do
      FakeWeb.register_uri(:post, 'http://myakismetkey.rest.akismet.com/1.1/comment-check', :body => 'false')
      assert @comment.save
      assert @comment.pending?
    end
  end
end
