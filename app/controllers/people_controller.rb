# Controlador para el registro de usuarios de tipo Person
class PeopleController < ApplicationController

  # def index
  #   @people = Person.approved.paginate :order => "people.created_at DESC", :page => params[:page], :per_page => 8
  #   @title = t('people.unidas')
  #   @breadcrumbs_info = [[t('people.unidas'), people_path]]
  # end
  #
  # def show
  #   begin
  #     @person = Person.approved.find(params[:id])
  #   rescue ActiveRecord::RecordNotFound
  #     flash[:notice] = t('people.not_found')
  #     redirect_to root_path and return
  #   end
  #   @title = "#{@person.public_name}"
  #   @title << ", #{t('people.de', :city => @person.public_city)}" if @person.public_city
  # end

  def intro
    session[:return_to] = request.referer || root_path
    if request.xhr?
      render :template => 'people/intro_for_nav', :layout => false and return
    end
  end

  # Se puede llegar al formulario new a través de intro o a través del
  # bloque de login. Por esto se asigna session[:return_to] aquí.
  def new
    session[:return_to] = request.referer || root_path
    @user = Person.new
    @user.wants_bulletin = true if params[:subscription].eql?('1')
    @title = t('people.registro_nuevo', :name => Settings.site_name)
    respond_to do |format|
      format.html {render :layout => layout2use4new}
    end
  end

  def create
    @user = Person.new(user_params)
    @user.user_ip = request.remote_ip
    if @user.save
      session[:new_user] = nil
      cookies.delete :auth_token
      email = Notifier.activate_person_account(@user)
      begin
        logger.info("Sending account activation email to #{@user.email}")
        email.deliver
      rescue Net::SMTPServerBusy, Net::SMTPSyntaxError => err_type
        logger.info("There was an error sending activation email: " + err_type)
        flash[:error] = t('session.Error_servidor_correo')
      end
      # flash[:tracking] = "/#{I18n.locale}/registered"
      render :layout => layout2use4new and return
    else
      render( :action => :new, :layout => layout2use4new) and return
    end
  end

  def edit
  end

  # Actualización de los datos personales
  def update
    @person = Person.approved.find(current_user.id)
    if @person.update_attributes(params[:person])
      redirect_to account_path
    else
      render :template => '/account/edit'
    end
  end

  # Esto debe moverse a otro controller porque usa prototype y en la parte publica solo jQuery
  # "Live validation" de los campos de registro
  def validate_field
    if params[:type].eql?('Person')
      user_attrs = ['email', 'password', 'password_confirmation', 'url', 'name', 'last_names']
    elsif  params[:type].eql?('Journalist')
      user_attrs = ['email', 'password', 'password_confirmation', 'media', 'url', 'name', 'last_names']
    else
      user_attrs = ['email', 'password', 'password_confirmation', 'telephone', 'name', 'last_names']
    end

    user_params = params.dup.delete_if {|k, v| !user_attrs.include?(k)}

    render :update do |page|
      if user_params.length > 0
        u = params[:type].constantize.new(user_params)
        u.valid?
        user_params.each do |pk, pv|
          if u.errors[pk.to_sym]
            page.select("#user_#{pk}_container span.error_message").each(&:remove)
            page.insert_html :after, "user_#{pk}", content_tag(:span, u.errors[pk.to_sym].to_a.join(' y '), :class => 'error_message')
          else
            page.select("#user_#{pk}_container span.error_message").each(&:remove)
          end
        end
      end
    end
  end

  private

  def make_breadcrumbs
    @breadcrumbs_info = [[t('people.register'), intro_people_path]]
    if params[:action].eql?('new')
      @breadcrumbs_info << [t('people.crea_tu_cuenta', :site_name => Settings.site_name), new_person_path]
    end
  end

  def layout2use4new
    layout2use = if session[:return_to].to_s.match("/embed/")
      @embed_layout = true
      "embed"
    else
      !request.xhr?
    end
    layout2use
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :last_names, :photo, :remove_photo, :subscription, :bulletin_email, :wants_bulletin, :alerts_locale, :normas_de_uso, :zip)
  end
end
