# Clase para los departamentos en los que se pueden clasificar los News y Events.
# Es subclase de Organization, por lo que su tabla es <tt>organizations</tt>
class Department < Organization
  has_many :organizations, :class_name => "Organization", :foreign_key => "parent_id"

  has_many :members, :class_name => 'User', :foreign_key => "department_id"

  has_many :sorganizations, -> { order("lower(name_#{I18n.locale})") }

  has_many :subscriptions
  has_many :proposals, :foreign_key => "organization_id"
  has_many :debates, :foreign_key => "organization_id"

  validates_presence_of :tag_name
  validates_format_of :tag_name, :with => /\A_[a-z0-9_]+\Z/
  validates_uniqueness_of :name_es, :tag_name

  scope :for_term, ->(*args) { where(["term = ?", args.first]).order('position')}

  # Legislaturas: se usan para poder separar los departamentos por legislatura
  # Las entidades no tienen asignada ninguna legislatura
  def self.terms
    @@terms ||= self.pluck(:term).uniq.compact
  end

  # Cada departamento tiene asociado un tag oculto que se añade automáticamente
  def self.tag_names
    self.select("tag_name").map {|d| d.tag_name}
  end

  # La etiqueta del departamento es su tag oculto sin el '_' al principio.
  # Se usa en las URL de acciones que muestran contentido sólo para un departamento.
  def label
    self.tag_name.gsub(/^_+/,'')
  end

  # Devuelve el departamento con la etiqueta indicada.
  def self.find_by_label(dept_label)
    tag_name = "_"+dept_label.gsub(/[^\w_]/,'')
    dept = self.tag_names.include?(tag_name) ? self.find_by_tag_name(tag_name) : nil
    dept
  end

  # Array de departamentos en formato óptimo para hacer un select en un view.
  # El formato del output es
  # <tt>[[[dep.nombre, dep.id], [[subdep1.nombre, subdep1.id], [subdep2.nombre, subdep2.id]...]], [[dep2.nombre, dep2.id], [...]]]</tt>
  def self.grouped_organizations_for_select
    Department.active.reorder("term, position").map{|a| [[a.name, a.id], a.organizations.active.map{|f|[f.name, f.id]}]}
  end

  def official_commenters
    candidates = self.members.approved
    list = candidates.select {|u| u.is_official_commenter?}
    list
  end

  def department_editors
    self.members.approved.where("type='DepartmentEditor'")
  end

  def department_members_official_commenters
    self.members.approved.where("type='DepartmentMember'").select {|u| u.is_official_commenter?}
  end

end
