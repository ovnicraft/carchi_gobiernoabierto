# Controlador para la administración de árboles de categorías
class Admin::TreesController < Admin::BaseController
  # in_place_edit_for :category, :tag_list
  # skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_category_tag_list]
  
  before_filter :get_tree, :only => [:show, :edit, :update, :destroy]
  
  # Listado de árboles
  def index
    @trees = Tree.all
    @title = 'Categorías'
    set_current_tab
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @trees }
    end
  end

  # Vista de un árbol
  def show
    @tree = Tree.find(params[:id])
    @title = "#{@tree.name_es} / #{@tree.name_eu}"
    set_current_tab
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tree }
    end
  end

  # Formulario de nuevo árbol
  def new
    @tree = Tree.new
    @title = 'Nueva sección'
    set_current_tab
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tree }
    end
  end

  # Modificar un árbol
  def edit
    @tree = Tree.find(params[:id])
    @title = "Modificar #{@tree.name_es}"
    set_current_tab                           
    respond_to do |format|
      format.html
      format.js
    end  
  end

  # Creación de un árbol
  def create
    @tree = Tree.new(tree_params)
    set_current_tab
    respond_to do |format|
      if @tree.save
        flash[:notice] = 'Tree was successfully created.'
        format.html { redirect_to(admin_tree_url(@tree)) }
        format.xml  { render :xml => @tree, :status => :created, :location => @tree }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tree.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualizar un árbol
  def update
    @tree = Tree.find(params[:id])
    set_current_tab
    
    respond_to do |format|
      if @tree.update_attributes(tree_params)
        flash[:notice] = 'Tree was successfully updated.'
        format.html { redirect_to(admin_tree_url(@tree)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tree.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Eliminar un árbol
  def destroy
    @tree = Tree.find(params[:id])
    @tree.destroy
    set_current_tab
    
    respond_to do |format|
      format.html { redirect_to(admin_trees_url) }
      format.xml  { head :ok }
    end
  end

  private
  
  def get_tree
    @tree = Tree.find(params[:id])
  end
  
  def set_current_tab
    @current_tab = :menus
    if @tree           
      case @tree.label
      when "videos"
        @current_subtab = :canales
      when "ma_menu"  
        @current_subtab = :ma_menu
      when "albums"  
        @current_subtab = :albums
      when "navbar_left"  
        @current_subtab = :navbar_left
      when "navbar_right"  
        @current_subtab = :navbar_right
      else
        @current_subtab = :categories
      end
    else
      @current_tab = :categories
    end
  end

  def tree_params
    params.require(:tree).permit(:name_es, :name_eu, :name_en)
  end
end
