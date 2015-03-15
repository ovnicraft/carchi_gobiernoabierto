require 'test_helper'

class ExternalComments::ClientTest < ActiveSupport::TestCase
  context "validations" do
    context "new client" do
      setup do
        @client = ExternalComments::Client.new
      end
    
      should "require name, code and url" do
        assert !@client.valid?
      
        assert @client.errors[:name]
        assert @client.errors[:code]
        assert @client.errors[:url]

        assert_equal true, @client.errors[:notes].empty?
      end
    
      should "set default organization if not provided" do
        assert @client.organization_id.blank?
        assert !@client.valid?
      
        default_dept = Department.order("id").first
        assert_equal default_dept.id, @client.organization_id
      end
    end
        
    should "not set organization_id for existing client if empty" do
      client = external_comments_clients(:euskadinet)
      client.organization_id = nil
      assert !client.valid?
      assert client.errors[:organization_id]
    end
    
  end

  context "countable" do
    setup do
      @client = FactoryGirl.create(:external_comments_client, :organization_id => organizations(:interior).id)
      @a_interior_external_comments_item = FactoryGirl.create(:external_comments_item, :client => @client)
      @stats_counter = @a_interior_external_comments_item.stats_counter
    end

    should "update stats_counter organization" do
      @client.update_attributes(:organization_id => organizations(:lehendakaritza).id)
      @stats_counter.reload
      assert_equal organizations(:lehendakaritza).id,  @stats_counter.organization_id
      assert_equal organizations(:lehendakaritza).id, @stats_counter.department_id
    end
  end
end
