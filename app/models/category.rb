# Clase para los items de los menús de navegación, tanto de Irekia, como de los canales de la WebTV
class Category < ActiveRecord::Base
  translates :name, :description
  include Sluggable

  belongs_to :tree
  belongs_to :parent, :class_name => "Category", :foreign_key => "parent_id"
  #validates_presence_of :name_es, :name_eu, :name_en
  validates_presence_of :name_es
  # validates_uniqueness_of :name_es, :name_eu, :name_en
  validates_length_of :name_es, :name_eu, :name_en, :maximum => 255, :allow_blank => true

  acts_as_tree :order => "position"
  acts_as_list :scope => :parent
  acts_as_ordered_taggable

  #Category::LANGUAGES = [:es, :eu, :en]
  Category::LANGUAGES = [:es]

  CLOSED_CAPTIONS_TAG = "_closed_captions"

  scope :roots, -> { where("parent_id IS NULL")}

  # Indica si esta categoría es un enlace en lugar de un contenedor de noticias o páginas
  def is_a_link?
    self.name.match(/\"(.+)\":(.+$)/)
  end

  alias_method :title, :name

  # Vídeos del área: son los vídeos que tienen el tag del área
  def videos
    private_tags = self.tags.all_private.collect {|t| t.name_es}
    Video.published.translated.tagged_with(private_tags.length > 0 ? private_tags : ['this category has no video'])
  end

  def videos_count
    # self.videos.count('distinct videos.id')
    # now self.videos is a relation
    self.videos.to_a.count
  end

  def albums(finder_opts={})
    unless @all_albums
      private_tags = self.tags.all_private.collect {|t| t.name_es}
      @all_albums = Album.published.with_photos.tagged_with(private_tags.length > 0 ? private_tags : ['this album has no video'], any: true, order_by_matching_tag_count: true)
    end
    @all_albums
  end

  def albums_count
    # self.albums.count('distinct albums.id')
    self.albums.to_a.count
  end

  # Las categorias que acaban con "+", no son link en los menús. Ese + no debe
  # salir en los breadcrumbs
  def pretty_name
    self.name.sub(/\+$/, '')
  end

  # Si una categoría tiene el tag del departamento, es el "channel" de ese departamento (para webtv y fototeca)
  def department
    all_department_tags = Department.tag_names
    common_tags = self.tag_list & all_department_tags
    output = common_tags.length > 0 ? Department.find_by_tag_name(common_tags.first) : nil
    return output
  end

  # def album_counter
  #   private_tags = self.tags.all_private.collect {|t| t.name_es}
  #   all_albums = (private_tags.length > 0) ? Album.published.count_tagged_with(private_tags) : nil
  # end

end
