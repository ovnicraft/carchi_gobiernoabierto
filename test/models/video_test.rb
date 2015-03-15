require 'test_helper'

class VideoTest < ActiveSupport::TestCase

  test "should empty published_at if video is set to draft" do
    video = videos(:last_video)
    assert video.published?
    video.draft = '1'
    video.save
    assert !video.published?
  end

  test "related events" do
    assert_equal [], videos(:every_language).related_events
    assert_equal [], videos(:every_language).events

    assert_equal [documents(:passed_event)],  videos(:featured_video).events
  end

  test "add event" do
    video = videos(:every_language)

    video.event_ids = [documents(:passed_event).id]
    assert video.save
    assert_equal [documents(:passed_event).id], video.event_ids
    assert_equal [documents(:passed_event)], video.events
  end

  test "remove video removes the related event" do
    video = videos(:video_with_event)
    assert_equal [documents(:emakunde_passed_event)], video.events

    assert_difference('RelatedEvent.count', -1) do
      assert video.destroy
    end
  end

  test "published and transated" do
    assert_nil Video.published.detect {|v| !v.published?}
    assert_nil Video.translated.detect {|v| !v.show_in_es?}
  end

  test "recent scope" do
    # expected_options = { :order => "published_at DESC", :limit => 10 }
    # assert_equal expected_options, Video.recent.proxy_options
    assert_equal Video.order("published_at DESC").limit(10), Video.recent
  end

  test "published translated recent scope" do
    ptr = Video.published.translated.recent

    assert ptr
    assert_nil ptr.detect {|v| !v.published?}
    assert_nil ptr.detect {|v| !v.show_in_es?}
    assert (ptr.length <= 10)
  end

  test "tagged_with named scope" do
    assert_equal [videos(:video_dept_interior)], Video.tagged_with(tags(:interior_tag))
    assert_equal [videos(:video_lehendakaritza), videos(:every_language)].map {|v| v.id}.sort, Video.tagged_with(tags(:lehendakaritza_tag)).map {|v| v.id}.sort
  end

  test "check for captions" do
    video = videos(:video_dept_interior)
    assert video.captions_file_name
    assert !video.captions_available?
  end

  test "check for subtitles" do
    video = videos(:video_with_subtitles)
    assert video.update_attribute(:subtitles_es, File.new(File.join(Rails.root, 'test/data', 'test.srt')))
    video.reload
    assert File.exists?("#{Rails.root}/public/uploads/subtitles/#{video.id}/es/test.srt")
    assert video.captions_file_name
    # captions available method
    assert_equal true, video.captions_available?

    # subtitles to text
    # no funciona! no coinciden los \r y \n y demás
    # assert_equal '¿Qué tal?Las habitaciones, los quirófanos, las urgencias, (lo más gordo asistencial), al nuevo edificio...', video.subtitles_es_to_text
    assert_equal nil, video.subtitles_eu_to_text

    # get times from keyword
    assert_equal [1], video.get_times_from_keyword('tal')

    # clean test assets
    dirname = File.dirname(video.subtitles_es.path).split('/')[0..-1].join('/')
    assert FileUtils.rm_rf(File.dirname(dirname))
  end

  test "subtitles to transcription" do
    video = videos(:video_with_subtitles)
    assert video.update_attribute(:subtitles_es, File.new(File.join(Rails.root, 'test/data', 'test.srt')))
    video.reload

    expected_transcription =  {"1" => "¿Qué tal?", "11" => "Las habitaciones, los quirófanos, las urgencias, (lo más gordo asistencial), al nuevo edificio"}

    assert_equal expected_transcription, video.transcription
    # clean test assets
    dirname = File.dirname(video.subtitles_es.path).split('/')[0..-1].join('/')
    assert FileUtils.rm_rf(File.dirname(dirname))
  end

  test "adding closed captions adds corresponding tagxx" do
    video = videos(:video_with_subtitles)
    assert !video.tag_list.include?(Category::CLOSED_CAPTIONS_TAG)
    video.update_attribute(:subtitles_es, File.new(File.join(Rails.root, 'test/data', 'test.srt')))
    assert video.tag_list.include?(Category::CLOSED_CAPTIONS_TAG)
    # Removing subtitles removes the tag
    video.update_attribute(:subtitles_es, nil)
    assert !video.tag_list.include?(Category::CLOSED_CAPTIONS_TAG)
  end

  test "should index to elasticsearch after save" do
    prepare_elasticsearch_test
    video = videos(:searchable_video)
    assert_deleted_from_elasticsearch video
    assert video.save
    assert_indexed_in_elasticsearch video
  end

  test "should delete from elasticsearch after destroy" do
    prepare_elasticsearch_test
    video = videos(:searchable_video)
    assert_deleted_from_elasticsearch video
    assert video.save
    assert_indexed_in_elasticsearch video
    assert video.destroy
    assert_deleted_from_elasticsearch video
  end

  context "syncronization between video areas and it's comments areas" do
    setup do
      @video = videos(:video_lehendakaritza)
      @video.comments.build(:body => "thoughtful comment", :user => users(:comentador_oficial))
      assert @video.save
    end

    should "have lehendakaritza area tag" do
      assert_equal [areas(:a_lehendakaritza)], @video.areas
      @video.comments.each do |comment|
        assert_equal [areas(:a_lehendakaritza).area_tag], comment.tags
      end
    end

    context "via area_tags=" do
      # This is what the form in admin/documents/edit_tags uses
      should "add new area to comment" do
        @video.area_tags= [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es]
        @video.save
        @video.reload
        assert @video.areas.include?(areas(:a_interior))
        @video.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        @video.area_tags = [areas(:a_interior).area_tag.name_es]
        @video.save
        @video.reload
        assert !@video.areas.include?(areas(:a_lehendakaritza))
        @video.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

      should "not sync tags that are not area tags" do
        new_tag = tags(:tag_politician_lehendakaritza)
        @video.area_tags = [new_tag.name_es]
        @video.save
        @video.reload
        assert @video.tags.include?(new_tag)
        @video.comments.each do |comment|
          assert !comment.tags.include?(new_tag)
        end
      end

    end

    context "via tag_list" do
      should "add new area to comment" do
        @video.tag_list.add areas(:a_interior).area_tag.name_es
        @video.save
        @video.reload
        assert @video.areas.include?(areas(:a_interior))
        @video.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        @video.tag_list.remove areas(:a_lehendakaritza).area_tag.name_es
        @video.save
        @video.reload
        assert !@video.areas.include?(areas(:a_lehendakaritza))
        @video.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

      should "not sync tags that are not area tags" do
        new_tag = tags(:tag_politician_lehendakaritza)
        @video.taggings.build(:tag => new_tag)
        @video.save
        @video.reload
        assert @video.tags.include?(new_tag)
        @video.comments.each do |comment|
          assert !comment.tags.include?(new_tag)
        end
      end
    end
  end

  context "countable" do
    setup do
      @a_interior_video = News.create(:title => "interior news", :organization_id => organizations(:pacad).id, :area_tags => [areas(:a_interior).area_tag.name_es])
      @stats_counter = @a_interior_video.stats_counter
    end

    should "have correct area and department in stats_counter" do
      assert_equal areas(:a_interior).id,  @stats_counter.area_id
      assert_equal organizations(:pacad).id, @stats_counter.organization_id
      assert_equal organizations(:interior).id, @stats_counter.department_id
    end

    should "update stats_counter area" do
      @a_interior_video.update_attributes(:area_tags => [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es])
      assert_equal areas(:a_lehendakaritza).id,  @stats_counter.area_id
    end

    should "update stats_counter organization" do
      @a_interior_video.update_attributes(:organization_id => organizations(:emakunde).id)
      assert_equal organizations(:emakunde).id,  @stats_counter.organization_id
      assert_equal organizations(:lehendakaritza).id, @stats_counter.department_id
    end
  end
end
