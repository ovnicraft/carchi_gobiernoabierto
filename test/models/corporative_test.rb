require 'test_helper'

class CorporativeTest < ActiveSupport::TestCase

  setup do
     @default_values = YAML::load_file(Corporative.file_name)
     @old_customized = @default_values.delete("customized")
     @old_site_name = @default_values["site_name"]
  end

  should "validate presence of site_name" do
    corporative = Corporative.new(@default_values.merge({:site_name => ""}))
    assert !corporative.valid?
    assert !corporative.errors['site_name'].empty?
  end

  should "validate presence of publisher name" do
    corporative = Corporative.new(@default_values.merge({:publisher => {:name => "", :address => "address"}}))
    assert !corporative.valid?
    assert !corporative.errors['publisher_name'].empty?
  end

  should "validate presence of publisher address" do
    corporative = Corporative.new(@default_values.merge({:publisher => {:name => "name", :address => ""}}))
    assert !corporative.valid?
    assert !corporative.errors['publisher_address'].empty?
  end

  should "validate presence of from email" do
    corporative = Corporative.new(@default_values.merge({:email_addresses => {:from => "", :contact => "", :proposal_moderators => ""}}))
    assert !corporative.valid?
    assert !corporative.errors['email_addresses_from'].empty?
    assert !corporative.errors['email_addresses_contact'].empty?
    assert !corporative.errors['email_addresses_proposal_moderators'].empty?
  end

  should "validate format of email addresses" do
    corporative = Corporative.new(@default_values.merge({:email_addresses => {:from => "wrong", :contact => "wrong", :proposal_moderators => "wrong"}}))
    assert !corporative.valid?
    assert !corporative.errors['email_addresses_from'].empty?
    assert !corporative.errors['email_addresses_contact'].empty?
    assert !corporative.errors['email_addresses_proposal_moderators'].empty?
  end

  context "save" do

    should "save values to file" do
      corporative = Corporative.new(@default_values.merge({:site_name => "Changed site name"}))
      assert corporative.save
      assert_equal "Changed site name", YAML::load_file(Corporative.file_name)["site_name"]
    end

    context "first configuration" do
      setup do
        d = YAML::load_file(Corporative.file_name)
        d['customized'] = false
        File.open(Corporative.file_name, 'w') {|f| f.write d.to_yaml }
      end
      should "set customized to true" do
        corporative = Corporative.new(@default_values.merge({:site_name => "Changed site name"}))
        assert corporative.save
        assert_equal true, YAML::load_file(Corporative.file_name)["customized"]
        assert_equal true, Settings.customized
        assert_equal "Changed site name", Settings.site_name
      end
    end

    teardown do
      # Restore previous value
      data = YAML::load_file(Corporative.file_name)
      data['site_name'] = @old_site_name
      data['customized'] = @old_customized
      File.open(Corporative.file_name, 'w') {|f| f.write data.to_yaml }
    end
  end
end
