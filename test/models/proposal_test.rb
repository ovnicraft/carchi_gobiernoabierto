require 'test_helper'

class ProposalTest < ActiveSupport::TestCase

 if Settings.optional_modules.proposals
  def default_values
    {:email => "test@example.com", :body_es => "Body", :title_es => "Titulo", :area_tags => [areas(:a_lehendakaritza).area_tag.name_es], :user_id => users(:visitante).id}
  end

  def teardown
    FileUtils.rm_rf(Dir["#{Rails.root}/test/uploads/proposal"])
  end

  test "title_es cannot be empty" do
    proposal = Proposal.new(default_values.merge(:title_es => ""))
    assert proposal.title_es.blank?
    assert !proposal.valid?
    assert_equal true, proposal.errors[:title_es].include?("El título no puede estar vacío")
  end

  test "user cannot be empty" do
    proposal = Proposal.new(default_values.merge(:user_id => nil))
    assert !proposal.valid?
    assert proposal.errors[:user_id].include?("no puede estar vacío")
  end

  test "name is set to user name" do
    proposal = Proposal.new(default_values.merge(:name => ""))
    assert proposal.valid?
    assert_equal proposal.user.public_name, proposal.name
  end

  test "class_name is Proposal" do
    proposal = Proposal.new(default_values.merge(:name => ""))
    assert_equal "Proposal", proposal.class_name
  end

  test "should index to elasticsearch after save" do
    prepare_elasticsearch_test
    proposal = proposals(:approved_and_published_proposal)
    assert_deleted_from_elasticsearch proposal
    assert proposal.save
    assert_indexed_in_elasticsearch proposal
  end

  test "should delete from elasticsearch after destroy" do
    prepare_elasticsearch_test
    proposal = proposals(:approved_and_published_proposal)
    assert_deleted_from_elasticsearch proposal
    assert proposal.save
    assert_indexed_in_elasticsearch proposal
    assert proposal.destroy
    assert_deleted_from_elasticsearch proposal
  end

  context "visitante's new proposal" do
    setup do
      @proposal = Proposal.create(default_values.merge(:user_id => users(:visitante).id))
    end
    should "have pending status" do
      assert @proposal.pending?
    end
  end

  context "admin's new proposal" do
    setup do
      @proposal = Proposal.new(default_values.merge(:user_id => users(:admin).id))
    end
    should "not create proposal" do
      # NOTA: No se puede usar proposal.valid? porque la comprobación del tipo del usuario se hace before_create
      assert !@proposal.save
      assert_equal true, @proposal.errors[:base].include?("No puede crear propuestas ciudadanas")
    end
  end

  should "not approve proposal without organization" do
    @proposal = Proposal.create(default_values)
    assert @proposal.pending?
    @proposal.status = 'aprobado'
    assert !@proposal.valid?
    assert @proposal.errors[:base].include?("No puedes aprobar la propuesta sin asignarle departamento antes")
  end

  should "not let politicians create proposals" do
    @proposal = Proposal.create(default_values.merge(:user_id => users(:politician_one).id))
    # NOTA: No se puede usar proposal.valid? porque la comprobación del tipo del usuario se hace before_create
    assert !@proposal.save
    assert @proposal.errors[:base].include?("No puede crear propuestas ciudadanas")
  end

  context "syncronization between proposal areas and it's comments areas" do
    setup do
      @proposal = proposals(:featured_proposal)
      @proposal.comments.create(:body => "thoughtful comment", :user => users(:comentador_oficial))
    end

    should "have lehendakaritza area tag" do
      assert_equal [areas(:a_lehendakaritza)], @proposal.areas
      @proposal.comments.each do |comment|
        assert_equal [areas(:a_lehendakaritza).area_tag], comment.tags
      end
    end

    context "via area_tags=" do
      # This is what the form in admin/documents/edit_tags uses
      should "add new area to comment" do
        @proposal.area_tags= [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es]
        assert @proposal.save!
        @proposal.reload
        assert @proposal.areas.include?(areas(:a_interior))
        @proposal.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        @proposal.area_tags = [areas(:a_interior).area_tag.name_es]
        @proposal.save
        @proposal.reload
        assert !@proposal.areas.include?(areas(:a_lehendakaritza))
        @proposal.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

    end

    context "via tag_list" do
      should "add new area to comment" do
        @proposal.tag_list.add areas(:a_interior).area_tag.name_es
        @proposal.save
        @proposal.reload
        assert @proposal.areas.include?(areas(:a_interior))
        @proposal.comments.each do |comment|
          assert comment.tags.include?(areas(:a_interior).area_tag)
        end
      end

      should "remove area from comment" do
        # una propuesta no se puede quedar sin área así que primero le añadimos otra
        @proposal.tag_list.add areas(:a_interior).area_tag.name_es
        @proposal.save
        @proposal.tag_list.remove areas(:a_lehendakaritza).area_tag.name_es
        @proposal.save
        @proposal.reload
        assert !@proposal.areas.include?(areas(:a_lehendakaritza))
        @proposal.comments.each do |comment|
          assert !comment.tags.include?(areas(:a_lehendakaritza).area_tag)
        end
      end

      should "not sync tags that are not area tags" do
        new_tag = tags(:tag_politician_lehendakaritza)
        @proposal.tag_list.add new_tag.name_es
        assert @proposal.save!
        @proposal.reload
        assert @proposal.tags.include?(new_tag)
        @proposal.comments.each do |comment|
          assert !comment.tags.include?(new_tag)
        end
      end
    end
  end

  context "countable" do
    setup do
      @a_interior_proposal = Proposal.create(default_values.merge(:organization_id => organizations(:interior).id, :area_tags => [areas(:a_interior).area_tag.name_es]))
      @stats_counter = @a_interior_proposal.stats_counter
    end

    should "have correct area and department in stats_counterxx" do
      assert_equal areas(:a_interior).id,  @stats_counter.area_id
      assert_equal organizations(:interior).id, @stats_counter.organization_id
      assert_equal organizations(:interior).id, @stats_counter.department_id
    end

    should "update stats_counter area" do
      @a_interior_proposal.update_attributes(:area_tags => [areas(:a_lehendakaritza).area_tag.name_es, areas(:a_interior).area_tag.name_es])
      assert_equal areas(:a_lehendakaritza).id,  @stats_counter.area_id
    end

    should "update stats_counter organization" do
      @a_interior_proposal.update_attributes(:organization_id => organizations(:lehendakaritza).id)
      assert_equal organizations(:lehendakaritza).id,  @stats_counter.organization_id
      assert_equal organizations(:lehendakaritza).id, @stats_counter.department_id
    end
  end
 end
end
