# Controlador para la gestión de categorías de los menús
class Admin::CategoriesController < Admin::BaseController
  before_filter :get_tree

  uses_tiny_mce :only => [:edit, :update], :options => TINYMCE_OPTIONS
  
  # cache_sweeper :category_sweeper, :only => [:create, :update, :destroy, :sort]
  
  # Listado de categorías
  def index
  end

  # Formulario de creación de categoría
  def new
    @category = @tree.categories.build
    @page_title = "Nueva categoría"
    respond_to do |format|
      format.html
      format.js
    end
  end

  # Creación de categoría
  def create
    @page_title = "Nueva categoría"
    @category = @tree.categories.build(category_params)
    if @category.parent
      @category.position = @category.parent.position + 1
    end
    respond_to do |format|
      if @category.save
        format.html { 
          flash[:notice] = 'category was successfully created.'
          redirect_to admin_tree_category_url(@tree, @category) 
        }
        format.js
      else
        format.html { render :action => "new" }
        format.js { render :action => "new" }
      end
    end
  end
  
  # Modificación de categoría
  def edit
    @category = @tree.categories.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  # Actualización de categoría
  def update
    @category = @tree.categories.find(params[:id])
    if @category.update_attributes(category_params)
      respond_to do |format|
        format.html {
          flash[:notice] = "La sección se ha actualizado correctamente"
          redirect_to admin_tree_path(@tree)
        }
        format.js
      end
    else
      respond_to do |format|
        format.html { render :action => "edit" }
        format.js { render :action => "edit" }
      end
    end
  end  

  # Eliminación de categoría
  def destroy
    @page_title = "Eliminar categoría"
    @category = Category.find(params[:id])
    if @category.destroy
      respond_to do |format|
        format.html { 
          flash[:notice] = 'La categoría se ha eliminado correctamente'
          redirect_to admin_tree_url(@tree) 
        }
        format.js
      end
    else
      respond_to do |format|
        format.html { 
          flash[:error] = 'La categoría NO se ha eliminado correctamente'
          redirect_to admin_tree_url(@tree) 
        }
        format.js {
          render :status => 402
        }
      end
    end
  end
  
  
  # Reordenación de categorías
  def sort
    @page_title = "Reordenar categorías"
    @categories = Category.where({:tree_id => params[:tree_id], :parent_id => params[:parent_id]})
    # The parameter containing the items to be ordered has different name depending on the sublist
    # we are ordering. Its name always starts with "categories"
    order_param = params.keys.select {|k| k =~ /categories/}[0]
    Category.transaction do 
      @categories.each do |cat|
        cat.position = params[order_param].index(cat.id.to_s) + 1
        cat.save
      end
    end
    render :nothing => true
  end

  # Modificación de tags de una categoría
  def edit_tags
    @category= @tree.categories.find(params[:id])
  end  

  private
  # Las categorías pertenecen siempre a un árbol, en este caso el de menú de Irekia, 
  # Canales e WebTV
  def get_tree
    begin
      @tree = Tree.find(params[:tree_id])
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "La sección no es correcta"
      redirect_to :back
    end
  end

  def category_params
    params.require(:category).permit(:name_es, :name_eu, :name_en, :parent_id, :tag_list, :description_es, :description_eu, :description_en)
  end
  
end
