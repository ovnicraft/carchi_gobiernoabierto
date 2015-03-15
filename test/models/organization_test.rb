require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase

  test "organizations for dept" do
    dept = organizations(:lehendakaritza)

    assert dept.is_a?(Department)
    assert_equal 1, dept.organizations.size
    assert_equal organizations(:emakunde), dept.organizations.first
  end

  test "grouped_options" do
    dept = organizations(:educacion)
    org = organizations(:organismo_educacion)

    go = Department.grouped_organizations_for_select
    assert go[1].is_a?(Array)
    assert_equal [dept.name, dept.id], go[1][0]
    assert_equal 2, go.first.size
    assert_equal [[org.name, org.id]], go[1][1]
  end

  test "organization events" do
    o = organizations(:interior)

    assert !o.events.blank?
    assert [o.id], o.events.map {|m| m.organization_id}.uniq
  end

  test "should not save organization with duplicated name" do
    org = Organization.new(organizations(:lehendakaritza).attributes)
    assert !org.valid?
    assert org.errors[:name_es].include?("ya está cogido")
  end

  test "should not save organization with empty name" do
    org = Organization.new(organizations(:lehendakaritza).attributes.merge(:name_es => nil))
    assert !org.valid?
    assert org.errors[:name_es].include?("no puede estar vacío")
  end

  if Rails.configuration.external_urls[:guia_uri]
  test "should have gc methods" do
    o = organizations(:interior)
    assert_nil o.gc_id
    assert !o.gc_link.present?

    assert o.update_attribute(:gc_id, 1)
    assert_equal 1, o.gc_id
    assert o.gc_link.present?
  end
  end

end
