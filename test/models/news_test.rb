require 'test_helper'

class NewsTest < ActiveSupport::TestCase

  test "should have title_es" do
    news = News.new
    assert !news.save
    assert_equal ["no puede estar vacío"], news.errors[:title_es]
  end

  test "department tag is assigned" do
    dept = organizations(:gobierno_vasco)
    news = News.new(:title => "Test", :body => "News boby")
    news.organization = dept
    news.valid?
    assert news.save
    assert news.tag_list.include?(dept.tag_name)
  end

  test "should have department" do
    news = News.new(:title => "Test", :body => "News body")
    assert !news.save
    assert_equal ["no puede estar vacío"], news.errors[:organization_id]
  end

  test "should not be rateable" do
    news = News.new(:title => "Test", :body => "News body", :organization => organizations(:gobierno_vasco), :has_ratings => true)
    assert news.save
    assert !news.has_ratings?
  end

  test "only one A featured" do
    assert_equal 1, News.where(["featured='1A'", true]).count
    assert_equal News.featured_a, documents(:featured_news)
    news = documents(:one_news)
    news.featured='1A'
    news.save
    assert_equal 1, News.where(["featured='1A'", true]).count
    assert_equal News.featured_a, documents(:one_news)
  end

  test "only four B featured" do
    first_news = News.create(:title => "Test", :body => "News body", :organization => organizations(:gobierno_vasco), :featured => '4B', :published_at => 1.month.ago)
    News.create!(:title => "Test", :body => "News body", :organization => organizations(:gobierno_vasco), :featured => '4B', :published_at => 3.weeks.ago)
    News.create!(:title => "Test", :body => "News body", :organization => organizations(:gobierno_vasco), :featured => '4B', :published_at => 2.weeks.ago)
    assert_equal 4, News.featured_4b.length
    news = documents(:one_news)
    news.featured='4B'
    news.save
    assert_equal 4, News.featured_4b.length
    assert !News.featured_4b.include?(first_news)
  end

  test "should create multimedia dir" do
    news = News.new :title_es => "News with multimedia_dir", :organization => organizations(:gobierno_vasco),
                    :body_es => "News with multimedia_dir", :multimedia_dir => "2009/12/02/news_with_multimedia",
                    :published_at => Date.parse("2009-12-02")
    news.valid?
    assert news.save
    assert File.exists?(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path))
    assert File.directory?(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path))
    FileUtils.rm_rf(Dir.glob(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path)))
  end


  test "should move multimedia files to trash when deleting news" do
    news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)

    prepare_content_for_news_with_multimedia(news)

    assert File.exists?(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path, "test.txt")), "File test.txt is missing"
    assert news.destroy
    assert !File.exists?(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path, "test.txt")), "File test.txt was not deleted"
    assert !File.exists?(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path)), "The directory is still present"

    assert File.exists?(File.join(news.dir_for_deleted, "test.txt"))

    clear_multimedia_dir(news)

    # # We have to put back the files where they belong to
    # FileUtils.mv(Dir.glob("#{Document::MULTIMEDIA_PATH}2009/borradas/12/02/news_with_multimedia"), "#{Document::MULTIMEDIA_PATH}2009/12/02/")
    # FileUtils.rm_rf(Dir.glob("#{Document::MULTIMEDIA_PATH}2009/borradas"))
  end

  test "when deleting a news with related webtv videos they are marked as draft and relationship is deleted" do
    news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)
    related_videos = news.webtv_videos
    related_videos.each do |rv|
      assert rv.published?
      assert rv.document_id == news.id
    end

    related_photos = news.gallery_photos
    related_photos.each do |rv|
      assert rv.document_id == news.id
    end

    related_album = news.album
    assert !related_album.draft?
    assert related_album.document_id == news.id

    assert_difference 'News.count', -1 do
      news.destroy
    end

    related_videos.each do |rv|
      rv.reload
      assert !rv.published?
      assert rv.document_id.nil?
    end

    related_photos.each do |rv|
      rv.reload
      assert rv.document_id.nil?
    end

    assert related_album.draft?
    assert related_album.document_id.nil?

  end

  # HT
  # test "should tweet published news" do
  #   publication_date = Time.zone.now - 1.hour
  #   news = News.new :title_es => "News to be tweeted", :organization => organizations(:gobierno_vasco),
  #                   :body_es => "News to be tweeted", :published_at => publication_date
  #   assert news.save
  #   assert news.tweets.count == 1
  #   assert news.tweets.first.tweet_at = publication_date
  # end
  #
  # test "should not tweet private (aka unpublished) news" do
  #   news = News.new :title_es => "News to be tweeted", :organization => organizations(:gobierno_vasco),
  #                   :body_es => "News to be tweeted", :published_at => nil
  #   assert news.save
  #   assert news.tweets.count == 0
  # end
  #
  # test "should not tweet news older than one month" do
  #   news = documents(:last_year_news)
  #   news.body_es = "Changed"
  #   assert_no_difference 'DocumentTweet.count' do
  #     news.save
  #   end
  #   assert_equal 0, news.tweets.count
  # end

  test "should be considered as translated" do
    news = documents(:translated_news)
    assert news.translated_to?("eu")
  end

  test "should be considered as untranslated" do
    news = documents(:untranslated_news)
    assert !news.translated_to?("eu")
  end

  test "untranslated_to_es_news should be untranslated" do
    news = documents(:untranslated_to_es_news)
    assert !news.translated_to?("es"), "Should not be translated to es but it is"
    assert !news.translated_to?("eu"), "Should not be translated to eu but it is"
    assert !news.translated_to?("en"), "Should not be translated to en but it is"
  end

  test "news belonging to lehendakaritza department should have its tag" do
    news = documents(:one_news)
    assert news.tags.include?(tags(:lehendakaritza_tag)), "one_news should have '_lehendakaritza' tag but it doesn't"
  end

  test "related events" do
    assert_equal [], documents(:one_news).related_events
    assert_equal [], documents(:one_news).events
    assert_equal [], documents(:one_news).event_ids

    assert_equal [related_events(:rel_news_event)], documents(:news_with_event).related_events

    assert_equal [documents(:emakunde_passed_event)], documents(:news_with_event).events
  end

  test "assign event" do
    news = documents(:news_with_event)
    assert_equal [documents(:emakunde_passed_event).id], news.event_ids

    assert_difference('RelatedEvent.count', 1) do
      news.event_ids = news.event_ids + [documents(:passed_event).id]
    end
    assert_equal [documents(:emakunde_passed_event).id, documents(:passed_event).id].sort, news.event_ids.sort
    assert_equal 2, news.events.count
    assert  news.events.include?(documents(:emakunde_passed_event))
    assert  news.events.include?(documents(:passed_event))
  end

  test "remove news removes the related event" do
    news = documents(:news_with_event)
    assert_equal [documents(:emakunde_passed_event).id], news.event_ids

    assert_difference('RelatedEvent.count', -1) do
      assert news.destroy
    end
  end

  test "should get attached audios" do
    news, pdf_at =  create_news_with_attached_pdf

    # Comprobamos que el audio sale en la lista de attached_audios
    # expected_list = {:es => [pdf_at], :eu => [pdf_at], :en => [], :all => [pdf_at]}
    assert_equal [pdf_at], news.attached_files

    assert news.has_files?

    assert_equal 1, news.attached_files(:es).length
    assert_equal 1, news.attached_files(:eu).length
    assert_equal 0, news.attached_files(:en).length
    
    # clean test assets
    assert FileUtils.rm_rf File.dirname(news.attachments.first.file.path)
    # Borramos la noticia para que el fichero no se quede en el directorio de attachments.
    news.destroy
  end

  test "should get all videos" do
    news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)

    prepare_content_for_news_with_multimedia(news)

    assert File.exists?(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path, "test.flv")), "File test.flv is missing"

    expected_videos = {:featured => File.join(news.multimedia_path, "test.flv"), :list => []}

    videos = news.videos
    assert_equal expected_videos[:featured], videos[:featured][:es]
    assert_equal expected_videos[:list], videos[:list][:es]
  end

  test "should get irekia subsite videos" do
    news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)

    prepare_content_for_news_with_multimedia(news)

    assert File.exists?(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path, "test.flv")), "File test.flv is missing"

    # Sólo hay un vídeo, así que va a :featured y no a :list
    expected_video = "#{news.multimedia_path}test.flv"

    videos = news.videos
    assert_equal expected_video, videos[:featured][:es]
  end

  test "should calculate cached keys if dont" do
    news=documents(:news_rake_related_docs)
    assert_nil news.cached_key
    str=news.text_with_selected_keywords
    assert_not_nil news.cached_key
  end

  test "should calculate cached keys after save" do
    news=documents(:news_rake_related_docs)
    assert_nil news.cached_key
    assert_no_difference 'News.count' do
      assert_difference 'CachedKey.count', +1 do
        assert news.save
      end
    end
    assert_not_nil news.cached_key
  end

  test "should index to elasticsearch after save" do
    prepare_elasticsearch_test
    news = documents(:translated_news)
    assert_deleted_from_elasticsearch news
    assert news.save
    assert_indexed_in_elasticsearch news
  end

  test "should delete from elasticsearch after destroy" do
    prepare_elasticsearch_test
    news = documents(:translated_news)
    assert_deleted_from_elasticsearch news
    assert news.save
    assert_indexed_in_elasticsearch news
    assert news.destroy
    assert_deleted_from_elasticsearch news
  end

  test "should not indexed to elasticsearch if published_at is future" do
    prepare_elasticsearch_test
    news = documents(:unpublished_news)
    assert_deleted_from_elasticsearch news
    assert news.save
    assert !news.published?
    assert_deleted_from_elasticsearch news
  end

  test "should index to elasticsearch related after save" do
    prepare_elasticsearch_test('related')
    news = documents(:translated_news)
    assert_deleted_from_elasticsearch news, Elasticsearch::Base::RELATED_URI
    assert news.save
    assert_indexed_in_elasticsearch news, Elasticsearch::Base::RELATED_URI
  end

  test "should delete from elasticsearch related after destroy" do
    prepare_elasticsearch_test('related')
    news = documents(:translated_news)
    assert_deleted_from_elasticsearch news, Elasticsearch::Base::RELATED_URI
    assert news.save
    assert_indexed_in_elasticsearch news, Elasticsearch::Base::RELATED_URI
    assert news.destroy
    assert_deleted_from_elasticsearch news, Elasticsearch::Base::RELATED_URI
  end

  test "get related documents with cached keys" do
    prepare_elasticsearch_test('news')
    news=documents(:news_rake_related_docs)
    assert_nil news.cached_key
    related=[]
    assert_no_difference 'News.count' do
      assert_difference 'CachedKey.count', +1 do
        related=news.get_related_news_by_keywords
      end
    end
    #  porque hemos puesto que el score tiene que ser mayor de 0.10
    assert_equal 0, related.size
    # assert_equal [documents(:untranslated_news)], related
    assert_not_nil news.cached_key
  end

  test "news belongs to area" do
    news = documents(:commentable_news)
    assert_equal areas(:a_lehendakaritza), news.area
  end

  test "set area" do
    news = documents(:commentable_news)
    assert_not_nil news.area

    new_area = areas(:a_ogov)
    news.area_tags = [new_area.area_tag.name_es]

    assert news.save!
    news.reload

    assert_equal new_area, news.area
  end

  test "assign empty area" do
    news = documents(:commentable_news)
    assert_not_nil news.area.id

    news.area_tags = []

    assert news.save!
    news.reload

    assert_nil news.area
  end


  test "set politicians" do
    news = documents(:commentable_news)
    assert news.politicians_tags.empty?

    politician1 = users(:politician_interior)
    politician2 = users(:politician_lehendakaritza)
    new_politicians = [politician1.tag.name, politician2.tag.name].join(", ")

    news.politicians_tag_list = new_politicians
    assert news.save!
    news.reload
    assert_equal new_politicians, news.politicians_tag_list

  end

  test "set area and politicians" do
    news = documents(:commentable_news)

    # Asignar el nuevo área
    assert_not_nil news.area
    new_area = areas(:a_ogov)
    news.area_tags = [new_area.area_tag.name_es]

    # Asignar los nuevos políticos
    assert news.politicians_tags.empty?
    politician1 = users(:politician_interior)
    politician2 = users(:politician_lehendakaritza)
    new_politicians = [politician1.tag.name, politician2.tag.name].join(", ")
    news.politicians_tag_list = new_politicians

    # Guaradary recargar los datos
    assert news.save!
    news.reload

    # Comprobamos el área y los políticos
    assert_equal new_area, news.area
    assert_equal new_politicians, news.politicians_tag_list
  end

  test "class_name is Document" do
    news = documents(:commentable_news)
    assert_equal "Document", news.class_name
  end

 if Settings.optional_modules.debates
  context "with debate" do

    should "have debate" do
      news = documents(:news_for_debate)
      debate = debates(:debate_completo)

      assert_equal debate, news.debate
    end

    should "assign debate" do
      news = documents(:irekia_news)
      debate = debates(:debate_nuevo)

      assert_nil news.debate

      news.debate_id = debate.id
      assert news.save

      assert_equal debate, news.debate
    end

    should "nullify news when deleted" do
      news = documents(:news_for_debate)
      debate = debates(:debate_completo)

      assert_equal debate, news.debate

      assert news.destroy

      debate.reload

      assert_nil debate.news_id
    end
  end
 end

  context "syncronization between news areas and it's comments areas" do
    setup do
      @news = documents(:commentable_news)
    end

    should "have lehendakaritza area tag" do
      assert_equal [areas(:a_lehendakaritza)], @news.areas
      @news.comments.each do |comment|
        assert_equal [areas(:a_lehendakaritza).area_tag], comment.tags
      end
    end

    context "via area_tags=" do
      # This is what the form in admin/documents/edit_tags uses
      should "add new area to comment" do
        @news.area_tags= [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es]
        @news.save
        @news.reload
        assert @news.areas.include?(areas(:a_interior))
        @news.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        @news.area_tags = [areas(:a_interior).area_tag.name_es]
        @news.save
        @news.reload
        assert !@news.areas.include?(areas(:a_lehendakaritza))
        @news.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

      should "not sync tags that are not area tags" do
        new_tag = tags(:tag_politician_lehendakaritza)
        @news.area_tags = [new_tag.name_es]
        @news.save
        @news.reload
        assert @news.tags.include?(new_tag)
        @news.comments.each do |comment|
          assert !comment.tags.include?(new_tag)
        end
      end

    end

    context "via tag_list" do
      should "add new area to comment" do
        @news.tag_list.add areas(:a_interior).area_tag.name_es
        @news.save
        @news.reload
        assert @news.areas.include?(areas(:a_interior))
        @news.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        @news.tag_list.remove areas(:a_lehendakaritza).area_tag.name_es
        @news.save
        @news.reload
        assert !@news.areas.include?(areas(:a_lehendakaritza))
        @news.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

      should "not sync tags that are not area tags" do
        new_tag = tags(:tag_politician_lehendakaritza)
        @news.tag_list.add new_tag.name_es
        assert @news.save
        @news.reload
        assert @news.tags.include?(new_tag)
        @news.comments.each do |comment|
          assert !comment.tags.include?(new_tag)
        end
      end
    end
  end

  context "with external comments" do
    setup do
      @news = documents(:commentable_news)
    end

    should "get all comments" do
      external_items = ExternalComments::Item.where(irekia_news_id: @news.id)
      all_comments = @news.comments
      external_items.each do |item|
        all_comments += item.comments
      end

      assert_equal all_comments.length, @news.all_comments.count
    end
  end

  # should "allow only n featured in bulletin" do
  #   first_news = News.create(:title => "Test", :body => "News body", :organization => organizations(:gobierno_vasco), :featured_bulletin => true, :published_at => 1.month.ago)
  #   News.create!(:title => "Test", :body => "News body", :organization => organizations(:gobierno_vasco), :featured_bulletin => true, :published_at => 3.weeks.ago)
  #   News.create!(:title => "Test", :body => "News body", :organization => organizations(:gobierno_vasco), :featured_bulletin => true, :published_at => 2.weeks.ago)
  #   news = documents(:one_news)
  #   news.featured_bulletin = true
  #   news.save
  #   news.reload
  #   assert news.featured_bulletin?
  #   first_news.reload
  #   assert !first_news.featured_bulletin?
  # end

  context "set_area_will_change" do
    setup do
      @a_interior_news = documents(:translated_news)
      assert_equal areas(:a_interior), @a_interior_news.area
    end

    should "change area via tag_list" do
      @a_interior_news.tag_list.add areas(:a_lehendakaritza).area_tag.name_es
      @a_interior_news.send("set_area_will_change")
      assert @a_interior_news.area_changed?
    end

    should "change area via area_tags" do
      @a_interior_news.area_tags = [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es]
      @a_interior_news.send("set_area_will_change")
      assert @a_interior_news.area_changed?
    end
  end

  context "countable" do
    setup do
      @a_interior_news = News.create(:title => "interior news", :organization_id => organizations(:pacad).id, :area_tags => [areas(:a_interior).area_tag.name_es])
      @stats_counter = @a_interior_news.stats_counter
    end

    should "have correct area and department in stats_counter" do
      assert_equal areas(:a_interior).id,  @stats_counter.area_id
      assert_equal organizations(:pacad).id, @stats_counter.organization_id
      assert_equal organizations(:interior).id, @stats_counter.department_id
    end

    should "update stats_counter area" do
      @a_interior_news.update_attributes(:area_tags => [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es])
      assert_equal areas(:a_lehendakaritza).id,  @stats_counter.area_id
    end

    should "update stats_counter organization" do
      @a_interior_news.update_attributes(:organization_id => organizations(:emakunde).id)
      assert_equal organizations(:emakunde).id,  @stats_counter.organization_id
      assert_equal organizations(:lehendakaritza).id, @stats_counter.department_id
    end
  end

end
