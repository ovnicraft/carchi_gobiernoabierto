ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'elasticsearch_test_helper'

include Shoulda::Matchers::ActiveRecord
extend Shoulda::Matchers::ActiveRecord
include Shoulda::Matchers::ActiveModel
extend Shoulda::Matchers::ActiveModel

class ActiveSupport::TestCase

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  set_fixture_class :external_comments_clients => ExternalComments::Client
  set_fixture_class :external_comments_items => ExternalComments::Item
  set_fixture_class :tags => ActsAsTaggableOn::Tag
  set_fixture_class :taggings => ActsAsTaggableOn::Tagging
  fixtures :all

  ActiveRecord::Migration.check_pending!

  include ElasticsearchTestHelper

  setup :global_setup
  teardown :global_teardown

  def global_setup
    # FakeWeb permite stubbear las llamadas a URL-s que se hacen a través de Net::HTTP
    # Aquí lo usamos para stubbear las llamadas a Akismet
    FakeWeb.allow_net_connect = %r{^http?://(127.0.0.1|maps.googleapis.com)} # permitir sólo las llamadas a localhost
    FakeWeb.register_uri(:post, 'http://myakismetkey.rest.akismet.com/1.1/submit-spam', :body => 'Thanks for making the web a better place')
    FakeWeb.register_uri(:post, 'http://myakismetkey.rest.akismet.com/1.1/comment-check', :body => 'false')
    I18n.locale = :es
    # Remove the cache for News.featured_a and News.featured_b
    Rails.cache.clear if File.exists?(File.join(Rails.root, 'tmp', 'cache'))
    UserActionObserver.current_user = nil
  end

  def global_teardown
    FakeWeb.clean_registry
    I18n.locale = :es
    # Remove the cache for News.featured_a and News.featured_b
    Rails.cache.clear if File.exists?(File.join(Rails.root, 'tmp', 'cache'))
    UserActionObserver.current_user = nil
  end

  # fixtures :users
  # Define login method to be used in functional tests.
  # Source: http://alexbrie.net/1526/functional-tests-with-login-in-rails/
  def login(email='foo@bar.com', password='fooblitzky')
    @old_controller = @controller
    @controller = SessionsController.new
    @request.env['REMOTE_ADDR'] = "http://127.0.0.1"
    post :create, :email => email, :password => password
    assert_redirected_to @controller.send('default_url_for_user')
    assert_not_nil(session[:user_id])
    @controller = @old_controller
  end

  def twitter_login(user)
    # @controller.current_user = users(user)
    # @controller.session = {}
    @request.session = {}
    @controller.send("current_user=", users(user))
    # session[:user_id] = users(user).id
  end

  def login_as(user)
    if user.eql?("twitter_user") || user.eql?("facebook_user")
      twitter_login(user)
    else
      login(users(user).email, 'test')
    end
  end

  def logout
    old_controller = @controller
    @controller = SessionsController.new
    delete :destroy
    assert_nil session[:user]
    assert_response :redirect
  end

  def assert_not_authorized
    # The response of access_denied method is :success, although it makes a redirect inside the respond_to block.
    # assert_response :redirect
    # So, here we check that no template is rendered.

    assert_equal I18n.t('no_tienes_permiso'), flash[:notice]
    assert_template nil
  end

  def should_not_be_empty(user, attr_name)
    assert !user.valid?
    assert user.errors[attr_name.to_sym].include?("no puede estar vacío")
  end

  def prepare_content_for_news_with_multimedia(news)
    # We copy one file in this new created directory
    FileUtils.mkdir_p(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path))
    FileUtils.cp(File.join(Document::MULTIMEDIA_PATH, 'photos', 'test.jpg'), File.join(Document::MULTIMEDIA_PATH, news.multimedia_path))
    FileUtils.cp(File.join(Document::MULTIMEDIA_PATH, 'test.txt'), File.join(Document::MULTIMEDIA_PATH, news.multimedia_path))
    FileUtils.cp(File.join(Document::MULTIMEDIA_PATH, 'test.txt'), File.join(Document::MULTIMEDIA_PATH, news.multimedia_path, 'photo_test.jpg'))
    FileUtils.cp(File.join(Document::MULTIMEDIA_PATH, 'test.txt'), File.join(Document::MULTIMEDIA_PATH, news.multimedia_path, 'test.flv'))
  end

  def clear_multimedia_dir(news)
    FileUtils.rm_rf(Dir.glob(File.join(Document::MULTIMEDIA_PATH, "2010")))
  end

  def assert_content_is_tracked(source, target)
    source_controller = source.is_a?(Criterio) ? 'search' : source.class.to_s.downcase
    # for named_spaced ones
    source_controller = source_controller.split('::').last
    # @request.env["HTTP_REFERER"] = url_for(:controller => source_controller, :action => 'show', :id => source.id, :locale => "es")
    @request.env["HTTP_REFERER"] = send("#{source_controller}_url", source)

    assert_difference 'Clickthrough.count', +1 do
      get :show, :id => target.to_param, :track => 1, :locale => "es"
      if target.is_a?(Debate)
        assert_response :redirect
      else
        assert_response :success
      end
    end

    last_clickthrough = Clickthrough.order("id DESC").first
    assert_equal source.class.base_class.name, last_clickthrough.click_source_type
    assert_equal source.id, last_clickthrough.click_source_id

    assert_equal target.class.base_class.name, last_clickthrough.click_target_type
    assert_equal target.id, last_clickthrough.click_target_id

    assert_equal last_clickthrough, source.clicks_from.last
    # assert_equal last_clickthrough, target.clicks_to.last
  end

  def assert_comment_counters(commentable)
    assert_equal commentable.comments.approved.count, commentable.stats_counter.comments, "Comments counter does not match"
    assert_equal commentable.comments.approved.official.count, commentable.stats_counter.official_comments, "Official comments counter does not match"
  end

  def assert_argument_counters(argumentable)
    assert_equal argumentable.arguments.published.count, argumentable.stats_counter.arguments, "Arguments counter does not match"
    assert_equal argumentable.arguments.published.in_favor.count, argumentable.stats_counter.in_favor_arguments, "In favor arguments counter does not match"
    assert_equal argumentable.arguments.published.against.count, argumentable.stats_counter.against_arguments, "Against arguments counter does not match"
  end

  def assert_vote_counters(votable)
    assert_equal votable.votes.count, votable.stats_counter.votes, "Votes counter does not match"
    assert_equal votable.votes.positive.count, votable.stats_counter.positive_votes, "Positive votes counter does not match"
    assert_equal votable.votes.negative.count, votable.stats_counter.negative_votes, "Negative votes counter does not match"
  end

  def create_news_with_attached_pdf
    news = News.new :title_es => "News with attached audio",
                    :organization => organizations(:gobierno_vasco),
                    :body_es => "News with  attached audio",
                    :published_at => Date.parse("2009-12-02")
    news.valid?
    assert news.save

    pdf_at = news.attachments.new
    pdf_at.file = File.new(File.join(Document::MULTIMEDIA_PATH, 'test.pdf'))
    assert pdf_at.save
    assert news.attachments.include?(pdf_at)

    return [news, pdf_at]
  end

  def assert_tag_in(*opts)
    target = HTML::Document.new(opts.shift, false, false)
    opts = opts.size > 1 ? opts.last.merge({ :tag => opts.first.to_s }) : opts.first
    assert !target.find(opts).nil?, "expected tag, but no tag found matching #{opts.inspect} in:\n#{target.inspect}"
  end

  def check_testing_soap
    @@testing_soap_checked ||= false
    if @@testing_soap_checked
    else
      unless TEST_SOAP
        puts "\n----------\nWarning: testing soap disabled\n----------\n"
      end
      @@testing_soap_checked = true
    end
  end

end

TEST_SOAP = false

CarrierWave.configure do |config|
  config.storage = :file
end

CarrierWave::Uploader::Base.descendants.each do |klass|
  next if klass.anonymous?
  klass.class_eval do
    # def cache_dir
    #   "#{Rails.root}/spec/support/uploads/tmp"
    # end

    def store_dir
      "#{Rails.root}/test/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  end
end

# To be able to use url_for in assert_content_is_tracked
class ActionController::TestCase
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper

  module Behavior
    def process_with_default_locale(action, http_method = 'GET', parameters = nil, session = nil, flash = nil)
      parameters = { :locale => I18n.locale }.merge( parameters || {} ) unless I18n.locale.nil?
      process_without_default_locale(action, http_method, parameters, session, flash)
    end
    alias_method_chain :process, :default_locale
  end

  def global_setup
    # For the HTTP authentication in controller tests
    # Source: http://railsforum.com/viewtopic.php?id=14315
    if Rails.application.secrets['http_auth']
      @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64::encode64("#{Rails.application.secrets['http_auth']['user_name']}:#{Rails.application.secrets['http_auth']['password']}")
    end
    super
  end
end

