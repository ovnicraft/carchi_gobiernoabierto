require 'test_helper'

class DebateTest < ActiveSupport::TestCase
 if Settings.optional_modules.debates
  def setup
    @debate_params = {:title_es => "Título en castellano del debate",
                      :body_es => "Introducción en castellano",
                      :description_es => "Descripción en castellano",
                      :organization_id => organizations(:lehendakaritza).id,
                      :hashtag => "#nuevodebate",
                      :multimedia_dir => "nuevodebate"}
  end

  def teardown
    FileUtils.rm_rf(Dir["#{Rails.root}/test/uploads/debate"])
  end

  context "create debate" do
    setup do
      @debate = Debate.new(@debate_params)
    end

    teardown do
      @debate.remove_cover_image!
      @debate.remove_header_image!
    end

    should "not validate if hashtag is empty" do
      @debate.hashtag = nil
      assert !@debate.valid?
      assert @debate.errors[:hashtag]
      assert_equal true, @debate.errors[:hashtag].include?("no puede estar vacío")
    end

    should "not validate if hashtag is not unique" do
      @debate.hashtag = debates(:debate_completo).hashtag
      assert !@debate.valid?
      assert @debate.errors[:hashtag]
      assert_equal true, @debate.errors[:hashtag].include?("ya está cogido")
    end

    should "not validate if hashtag is not unique case insensitive" do
      @debate.hashtag = debates(:debate_completo).hashtag.upcase
      assert !@debate.valid?
      assert @debate.errors[:hashtag]
      assert_equal true, @debate.errors[:hashtag].include?("ya está cogido")
    end

    should "not validate if multimedia_dir contains invalid characters" do
      @debate.multimedia_dir = " á "
      assert !@debate.valid?
      assert @debate.errors[:multimedia_dir]
      assert_equal true, @debate.errors[:multimedia_dir].include?("no es válido")
    end

    should "create a tag on create" do
      assert @debate.valid?

      assert_difference "ActsAsTaggableOn::Tagging.count", 1 do
        assert_difference "ActsAsTaggableOn::Tag.count", 1 do
          assert @debate.save
        end
      end

      debate_tag = @debate.tags.first
      assert_equal "hashtag_#{@debate.hashtag.gsub(/#/,'')}", debate_tag.sanitized_name_es
      assert_equal "hashtag_#{@debate.hashtag.gsub(/#/,'')}", debate_tag.sanitized_name_eu
      assert_equal "hashtag_#{@debate.hashtag.gsub(/#/,'')}", debate_tag.sanitized_name_en

      assert_equal @debate.hashtag, @debate.tags.first.name_es
    end

    should "add # to the hashtag unless present" do
      @debate.hashtag = "nuevodebate"
      assert @debate.save
      assert_equal "#nuevodebate", @debate.hashtag
    end

    should "add debate as prefix for multimedia_dir" do
      assert @debate.valid?
      assert @debate.save
      assert_not_nil @debate.multimedia_path
    end

    should "set_multimedia_path" do
      assert @debate.valid?
      assert @debate.save
      assert_not_nil @debate.multimedia_path
    end

    should "create multimedia dir" do
      assert @debate.valid?
      assert @debate.save
      assert_not_nil @debate.multimedia_path

      assert_match /^debates\//, @debate.multimedia_path

      assert File.exists?(File.join(Debate::MULTIMEDIA_PATH, @debate.multimedia_path))
      assert File.directory?(File.join(Debate::MULTIMEDIA_PATH, @debate.multimedia_path))
      FileUtils.rm_rf(Dir.glob(File.join(Debate::MULTIMEDIA_PATH, @debate.multimedia_path)))
    end

    context "set default image" do
      should "if empty" do
        assert_equal false, @debate.cover_image.present?
        assert @debate.save
        assert_equal true, @debate.cover_image.present?
        assert_equal true, @debate.header_image.present?
        assert_equal 'debate_default_00.jpg', @debate.cover_image.url.split('/').last
      end

      should "increment default image index" do
        assert @debate.save
        assert_equal 'debate_default_00.jpg', @debate.cover_image.url.split('/').last
        @debate2 = Debate.new(@debate_params.merge(:hashtag => "#nuevodebate2"))
        assert @debate2.save
        assert_equal 'debate_default_01.jpg', @debate2.cover_image.url.split('/').last
        @debate3 = Debate.new(@debate_params.merge(:hashtag => "#nuevodebate3"))
        assert @debate3.save
        assert_equal 'debate_default_02.jpg', @debate3.cover_image.url.split('/').last
        @debate4 = Debate.new(@debate_params.merge(:hashtag => "#nuevodebate4"))
        assert @debate4.save
        assert_equal 'debate_default_03.jpg', @debate4.cover_image.url.split('/').last
        @debate5 = Debate.new(@debate_params.merge(:hashtag => "#nuevodebate5"))
        assert @debate5.save
        assert_equal 'debate_default_00.jpg', @debate5.cover_image.url.split('/').last
      end
    end

    should "get stages" do
      @debate.init_stages
      assert_equal @debate.stages.detect {|s| s.label.eql?('presentation')}, @debate.presentation_stage
      assert_equal @debate.stages.detect {|s| s.label.eql?('discussion')}, @debate.discussion_stage
      assert_equal @debate.stages.detect {|s| s.label.eql?('contribution')}, @debate.contribution_stage
      assert_equal @debate.stages.detect {|s| s.label.eql?('conclusions')}, @debate.conclusions_stage
    end

    context "stages dates" do
      setup do
        @debate.init_stages
        assert @debate.presentation_stage
        assert @debate.discussion_stage
        assert @debate.contribution_stage
        assert @debate.conclusions_stage

        @stage_presentation = @debate.stages.detect {|s| s.label.eql?('presentation')}
        @stage_discussion = @debate.stages.detect {|s| s.label.eql?('discussion')}
        @stage_contribution = @debate.stages.detect {|s| s.label.eql?('contribution')}
        @stage_conclusions = @debate.stages.detect {|s| s.label.eql?('conclusions')}

        @stage_presentation.starts_on = Date.today
        @stage_discussion.starts_on = 2.days.from_now.to_date
        @stage_contribution.starts_on = 3.days.from_now.to_date
        @stage_conclusions.starts_on = 4.days.from_now.to_date
        @stage_conclusions.ends_on = 5.days.from_now.to_date
      end

      should "set pulished_at and finished_at to nil for draft debate" do
        assert @debate.draft.eql?("1")

        assert @debate.save
        assert_nil @debate.published_at
        assert_nil @debate.finished_at
      end

      should "assign presentation stage starts_on as published_at for published debate" do
        assert @debate.draft = 0

        assert @debate.save
        assert_equal @stage_presentation.starts_on, @debate.published_at.to_date
      end

      should "assign conclusions stage ends_on as finished_at for published debate" do
        assert @debate.draft = 0

        assert @debate.save
        assert_equal @stage_conclusions.ends_on, @debate.finished_at.to_date
      end

      should "save debate even if stage dates are not ordered" do
        @debate.presentation_stage.starts_on = 2.days.from_now.to_date
        @debate.discussion_stage.starts_on = 1.day.from_now.to_date
        @debate.contribution_stage.starts_on = 4.days.from_now.to_date
        @debate.conclusions_stage.starts_on = 3.days.from_now.to_date
        @debate.conclusions_stage.ends_on = 5.days.from_now.to_date
        assert @debate.save
        assert @debate.errors.empty?
      end

      should "save debate if stage dates are ordered" do
        @debate.presentation_stage.starts_on = 1.days.from_now.to_date
        @debate.discussion_stage.starts_on = 2.day.from_now.to_date
        @debate.contribution_stage.starts_on = 3.days.from_now.to_date
        @debate.conclusions_stage.starts_on = 4.days.from_now.to_date
        @debate.conclusions_stage.ends_on = 5.days.from_now.to_date
        assert @debate.save
        assert @debate.errors.empty?
      end

      should "set stage positions" do
        assert @debate.save
        assert_equal 1, @debate.presentation_stage.position
        assert_equal 2, @debate.discussion_stage.position
        assert_equal 3, @debate.contribution_stage.position
        assert_equal 4, @debate.conclusions_stage.position
      end

    end
  end

  context "update debate" do
    setup do
      @debate = Debate.create(@debate_params)
      @debate.init_stages
      assert_equal true, @debate.save

      DebateStage::STAGES.each do |stage_label|
        assert_not_nil @debate.send("#{stage_label}_stage")
      end
    end

    should "not be finished if not published" do
      assert_nil @debate.finished_at
      assert !@debate.finished?
    end

    should "update debate tag if hashtag is changed" do
      old_hashtag = @debate.hashtag
      debate_tag = @debate.tags.find_by_name_es(@debate.hashtag)

      new_hashtag = "#nuevohashtag"
      @debate.hashtag = new_hashtag
      assert @debate.valid?

      assert_no_difference "ActsAsTaggableOn::Tagging.count" do
        assert_no_difference "ActsAsTaggableOn::Tag.count" do
          assert @debate.save
        end
      end

      debate_tag.reload
      assert_equal "hashtag_nuevohashtag", debate_tag.sanitized_name_es
      assert_equal "hashtag_nuevohashtag", debate_tag.sanitized_name_eu
      assert_equal "hashtag_nuevohashtag", debate_tag.sanitized_name_en
      assert_equal @debate.hashtag, debate_tag.name_es
    end

    should "add # to the hashtag unless present" do
      @debate.hashtag = "nuevodebate"
      assert @debate.save
      assert_equal "#nuevodebate", @debate.hashtag
    end

    should "not change multimedia_dir on update" do
      old_multimedia_dir = @debate.multimedia_dir

      @debate.title_es = "Cambio de título"
      assert @debate.save

      @debate.reload
      assert_equal old_multimedia_dir, @debate.multimedia_dir
    end

    should "save debate even if stage dates are not in order" do
      @debate.presentation_stage.starts_on = 2.days.from_now.to_date
      @debate.discussion_stage.starts_on = 1.day.from_now.to_date
      @debate.contribution_stage.starts_on = 4.days.from_now.to_date
      @debate.conclusions_stage.starts_on = 3.days.from_now.to_date
      @debate.conclusions_stage.ends_on = 5.days.from_now.to_date
      assert @debate.save
      assert @debate.errors.empty?
    end

    should "save debate if stage dates are in order" do
      @debate.presentation_stage.starts_on = 1.days.from_now.to_date
      @debate.presentation_stage.ends_on = 1.days.from_now.to_date
      @debate.discussion_stage.starts_on = 2.day.from_now.to_date
      @debate.contribution_stage.starts_on = 3.days.from_now.to_date
      @debate.conclusions_stage.starts_on = 4.days.from_now.to_date
      @debate.conclusions_stage.ends_on = 5.days.from_now.to_date
      assert @debate.save
      assert @debate.errors.empty?
    end

    should "destroy non active stages" do
      stages_attributes = @debate.stages.map {|s| {:id => s.id, :label => s.label, :starts_on => s.starts_on, :ends_on => s.ends_on, :position => s.position}}
      stages_attributes.last["_destroy"] = 1
      assert_difference "DebateStage.count", -1 do
        @debate.stages_attributes = stages_attributes
        @debate.save
      end
    end
  end

  context "debate completo" do
    setup do
      @debate = debates(:debate_completo)
      assert @debate.stages.present?
    end

    should "respond to class_name" do
      assert_equal "Debate", @debate.class_name
    end

    should "get stages ordered by position" do
      assert_equal DebateStage::STAGES, @debate.stages.map {|s| s.label.to_sym}

      assert @debate.contribution_stage.update_attribute(:position, 10)
      @debate.reload
      assert_equal [:presentation, :discussion, :conclusions, :contribution].to_s, @debate.stages.map {|s| s.label.to_sym}.to_s
    end

    should "get current stage for finished debate" do
      assert @debate.stages.last.ends_on < Date.today
      assert @debate.finished?

      assert_equal "conclusions", @debate.current_stage.label
    end

    should "get current stage for future debate" do
      @debate.stages.each_with_index do |s, i|
        s.update_attributes(:starts_on => Date.today + (i+1).months, :ends_on => Date.today + (i+2).months)
      end
      assert @debate.future?
      assert_equal "presentation", @debate.current_stage.label
    end

    should "get current stage for debate in presentation" do
      @debate.stages.each_with_index do |s, i|
        s.update_attributes(:starts_on => Date.today + (i+1).months, :ends_on => Date.today + (i+2).months)
      end
      @debate.stages.first.update_attributes(:starts_on => Date.today, :ends_on => Date.today + 1.months)
      @debate.save

      assert !@debate.finished?
      assert !@debate.future?
      assert @debate.current_stage.eql?(@debate.stages.first)
    end

    should "get current stage for debate in discussion" do
      @debate.stages.each_with_index do |s, i|
        s.update_attributes(:starts_on => Date.today + (i+1).months, :ends_on => Date.today + (i+2).months)
      end
      @debate.stages.first.update_attributes(:starts_on => Date.today - 1.month, :ends_on => Date.today - 1.day)
      @debate.stages[1].update_attributes(:starts_on => Date.today, :ends_on => Date.today + 1.months)
      @debate.save!

      assert !@debate.finished?
      assert !@debate.future?
      assert @debate.current_stage.eql?(@debate.stages[1])
    end

    should "get current stage for debate in contribution" do
      @debate.stages.each_with_index do |s, i|
        s.update_attributes(:starts_on => Date.today + (i+1).months, :ends_on => Date.today + (i+2).months)
      end
      @debate.stages.first.update_attributes(:starts_on => Date.today - 2.month, :ends_on => Date.today - 1.month - 1.day)
      @debate.stages[1].update_attributes(:starts_on => Date.today - 1.month, :ends_on => Date.today - 1.day)
      @debate.stages[2].update_attributes(:starts_on => Date.today, :ends_on => Date.today + 1.months)
      @debate.save!

      assert !@debate.finished?
      assert !@debate.future?
      assert @debate.current_stage.eql?(@debate.stages[2])
    end

    should "get current stage for debate in conclusions" do
      @debate.stages.each_with_index do |s, i|
        s.update_attributes(:starts_on => Date.today + (i+1).months, :ends_on => Date.today + (i+2).months)
      end
      @debate.stages[0].update_attributes(:starts_on => Date.today - 3.month, :ends_on => Date.today - 2.month - 1.day)
      @debate.stages[1].update_attributes(:starts_on => Date.today - 2.month, :ends_on => Date.today - 1.month - 1.day)
      @debate.stages[2].update_attributes(:starts_on => Date.today - 1.month, :ends_on => Date.today - 1.day)
      @debate.stages[3].update_attributes(:starts_on => Date.today, :ends_on => Date.today + 1.months)
      @debate.save!

      assert !@debate.finished?
      assert !@debate.future?
      assert @debate.current_stage.eql?(@debate.stages[3])
    end
  end

  context "syncronization between debate areas and it's comments areas" do
    setup do
      @debate = debates(:debate_nuevo)
      @debate.comments.create(:body => "thoughtful comment", :user => users(:comentador_oficial))
    end

    should "have lehendakaritza area tag" do
      assert_equal [areas(:a_lehendakaritza)], @debate.areas
      assert @debate.comments.count > 0
      @debate.comments.each do |comment|
        assert_equal [areas(:a_lehendakaritza).area_tag], comment.tags
      end
    end


    context "via area_tags=" do
      # This is what the form in admin/documents/edit_tags uses
      should "add new area to comment" do
        @debate.area_tags= [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es]
        assert @debate.save
        @debate.reload
        assert @debate.areas.include?(areas(:a_interior))
        assert @debate.areas.include?(areas(:a_lehendakaritza))
        @debate.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        @debate.area_tags = [areas(:a_interior).area_tag.name_es]
        @debate.save
        @debate.reload
        assert !@debate.areas.include?(areas(:a_lehendakaritza))
        @debate.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

      should "not sync tags that are not area tags" do
        new_tag = tags(:tag_politician_lehendakaritza)
        @debate.area_tags = [new_tag.name_es]
        @debate.save
        @debate.reload
        assert @debate.tags.include?(new_tag)
        @debate.comments.each do |comment|
          assert !comment.tags.include?(new_tag)
        end
      end

    end

    context "via tag_list" do
      should "add new area to comment" do
        @debate.tag_list.add areas(:a_interior).area_tag.name_es
        @debate.save
        @debate.reload
        assert @debate.areas.include?(areas(:a_interior))
        @debate.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        @debate.tag_list.remove areas(:a_lehendakaritza).area_tag.name_es
        @debate.save
        @debate.reload
        assert !@debate.areas.include?(areas(:a_lehendakaritza))
        @debate.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

      should "not sync tags that are not area tags" do
        new_tag = tags(:tag_politician_lehendakaritza)
        @debate.tag_list.add(new_tag.name)
        @debate.save
        @debate.reload
        assert @debate.tags.include?(new_tag)
        @debate.comments.each do |comment|
          assert !comment.tags.include?(new_tag)
        end
      end
    end
  end

  context "scopes" do
    should "get publihed debates" do
      published = Debate.published.map {|d| d.id if d.published?}.compact.sort
      expected_published = Debate.all.map {|d| d.id if d.published?}.compact.sort

      assert published.length > 0
      assert_equal expected_published, published
    end

    should "get finished debates" do
      finished = Debate.finished.map {|d| d.id}.sort
      expected_finished = Debate.all.map {|d| d.id if d.stages.last.ends_on < Date.today}.compact.sort

      assert finished.length > 0
      assert_equal expected_finished, finished
    end

    should "get current debates" do
      current = Debate.current.map {|d| d.id}.sort
      expected_current = Debate.all.map {|d| d.id  if d.published_at.present? && d.stages.last.ends_on >= Date.today}.compact.sort

      assert current.length > 0
      assert_equal expected_current, current
    end

  end

  test "should index to elasticsearch after save" do
    prepare_elasticsearch_test
    debate = debates(:debate_completo)
    assert_deleted_from_elasticsearch debate
    assert debate.save
    assert_indexed_in_elasticsearch debate
  end

  test "should delete from elasticsearch after destroy" do
    prepare_elasticsearch_test
    debate = debates(:debate_completo)
    assert_deleted_from_elasticsearch debate
    assert debate.save
    assert_indexed_in_elasticsearch debate
    assert debate.destroy
    assert_deleted_from_elasticsearch debate
  end

  context "featured bulletin" do
    setup do
      @current_featured = debates(:debate_completo)
      @current_featured.update_attribute(:featured_bulletin, true)
    end

    should "Return correct featured" do
      assert_equal Debate.featured_bulletin, [@current_featured]
    end

    should "Remove featured bulletin flag when featuring a new one" do
      new_featured = debates(:debate_nuevo)
      new_featured.update_attributes(:featured_bulletin => true)
      assert new_featured.featured_bulletin?
      @current_featured.reload
      assert !@current_featured.featured_bulletin?
    end
  end

  context "countable" do
    setup do
      @a_interior_debate = Debate.create(@debate_params.merge({:organization_id => organizations(:interior).id, :area_tags => [areas(:a_interior).area_tag.name_es]}))
      @stats_counter = @a_interior_debate.stats_counter
    end

    should "have correct area and department in stats_counter" do
      assert_equal areas(:a_interior).id,  @stats_counter.area_id
      assert_equal organizations(:interior).id, @stats_counter.organization_id
      assert_equal organizations(:interior).id, @stats_counter.department_id
    end

    should "update stats_counter area" do
      @a_interior_debate.update_attributes(:area_tags => [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es])
      assert_equal areas(:a_lehendakaritza).id,  @stats_counter.area_id
    end

    should "update stats_counter organization" do
      @a_interior_debate.update_attributes(:organization_id => organizations(:lehendakaritza).id)
      assert_equal organizations(:lehendakaritza).id,  @stats_counter.organization_id
      assert_equal organizations(:lehendakaritza).id, @stats_counter.department_id
    end
  end
 end
end
