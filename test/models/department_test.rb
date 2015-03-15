require 'test_helper'

class DepartmentTest < ActiveSupport::TestCase
  
  test "label" do
    assert_equal 'interior', organizations(:interior).label
    assert_equal organizations(:interior), Department.find_by_label(organizations(:interior).label)
  end

  test "should not save department with duplicated tag_name" do
    org = Department.new(organizations(:lehendakaritza).attributes)
    assert !org.valid?
    assert org.errors[:tag_name].include?("ya está cogido")
  end
  
  test "should not save department with empty tag_name" do
    org = Department.new(:name_es => "nuevo departamento", :tag_name => nil)
    assert !org.valid?
    assert org.errors[:tag_name].include?("no puede estar vacío")
  end
  
  test "should not save department with invalid tag_name" do
    org = Department.new(:name_es => "nuevo departamento", :tag_name => "this is inválid")
    assert !org.valid?
    assert org.errors[:tag_name].include?("no es válido")
  end  
  
  test "department editors" do
    lehendakaritza = organizations(:interior)
    assert_equal ['DepartmentEditor'], lehendakaritza.department_editors.collect(&:type).collect(&:to_s).uniq
  end
  
  test "department members official commenters" do
    lehendakaritza = organizations(:interior)
     
    lehendakaritza.department_members_official_commenters.each do |miembro|
      assert miembro.is_a?(DepartmentMember) && miembro.is_official_commenter?
    end
    
  end
  
  test "should set active to true for new department" do
    org = Department.new(:name_es => "nuevo departamento", :tag_name => "_new_department")
    assert org.save
    org.reload
    assert org.active?
  end
  
  test "should get only active departments" do
    active_depts = Department.active
    assert active_depts.length > 0 # nos aseguramos que hay departamentos activos
    assert active_depts.length < Department.count # nos aseguramos que el total de departamentos es más que los activos
    assert_nil active_depts.detect {|d| !d.active?}
  end
  
  test "should get only departemts for IX term" do
    depts_ix = Department.where("term = 'IX'").map {|d| d.id}.sort
    assert_equal depts_ix, Department.for_term("IX").map {|d| d.id}.sort
  end
  
end
