# encoding: UTF-8
require File.join(Rails.root, 'config', 'environment')
require 'csv'

namespace 'export' do
  desc "Export users data"
  task :export_users do
    p "Exporting users data ..."

    filename = "#{Document::EXPORT_PATH}/datos_usuarios.csv"
    @users = User.approved.where("email not like '%efaber%'").order("id")
    CSV.open(filename, "w", ";") do |writer|
      writer << ['id', 'Email', 'Contraseña', 'Salt', \
                 'Twitter screen_name', 'Twitter atoken', 'Twitter asecret', 'Facebook ID', \
                 'Nombre', 'Apellidos', 'Tipo', 'Departamento', 'Lugar', 'Código postal', 'Provincia', 'Ciudad']

      @users.each do |user|
        department = user.respond_to?("department") ? user.department.name : ""
        writer << [user.id, "#{user.email}", "#{user.crypted_password}", "#{user.salt}",\
                   "#{user.screen_name}", "#{user.atoken}", "#{user.asecret}", "#{user.fb_id}", \
                   "#{user.name}", "#{user.last_names}", "#{User::TYPES[user.type]}", \
                   "#{department}", "#{user.raw_location}", "#{user.zip}", "#{user.state}", "#{user.city}"]
      end
    end

    p "Export saved to #{filename}"
  end

  desc "Export areas"
  task :irekia_areas do
    filename = "#{Document::EXPORT_PATH}/datos_areas.yml"
    f = File.open(filename, 'w')
    f.write Area.all.to_yaml
    f.close
    p "Export saved to #{filename}"
  end

  desc "Expor políticos"
  task :irekia_politicos do
    filename = "#{Document::EXPORT_PATH}/datos_politicos.yml"
    f = File.open(filename, 'w')
    f.write Politician.approved.to_yaml
    f.close
    p "Export saved to #{filename}"
  end

  desc "Export accesos de políticos"
  task :irekia_politicians_last_login do
    filename = "#{Document::EXPORT_PATH}/ultimos_accesos_politicos.csv"
    politicians = Politician.approved
    CSV.open(filename, "w", ";") do |writer|
      writer << ['URL', 'Email', 'Nombre', 'Áreas', 'Último acceso']

      politicians.each do |user|
        last_login = user.session_logs.find :first, :order => "action_at DESC"
        writer << ["https://www.irekia.euskadi.net/es/admin/users/#{user.id}", "#{user.email}", "#{user.public_name}", "#{user.areas.map {|a| a.name}.join(", ")}", "#{last_login.present? ? last_login.updated_at.to_date : ''}"]
      end
    end

    p "Export saved to #{filename}"
  end

  desc "Export de propuestas ciudadanas"
  task :irekia_citizens_proposals do
    filename = "#{Document::EXPORT_PATH}/citizens_proposals.csv"
    proposals = Proposal.order("published_at DESC")
    CSV.open(filename, "w", ";") do |writer|
      writer << ["id", "Propuesta", "Fecha propuesta", "Nº comentarios oficiales", "Quién", "Para quién", "Departamento"]
      proposals.each do |proposal|
        from_who = proposal.user.present? ? proposal.user.public_name : nil
        for_whom = proposal.area.present? ? proposal.area.name : nil
        department = proposal.department.present? ? proposal.department.name : nil
        official_comments = proposal.comments.select {|c| c.user && c.user.is_official_commenter?}.length
        writer << [proposal.id, proposal.title, proposal.published_at, official_comments, from_who, for_whom, department]
      end
    end
    p "Export saved to #{filename}"
  end

  desc "Export de eventos"
  task :irekia_events do
    filename = "#{Document::EXPORT_PATH}/events.csv"
    events = Event.published.order("starts_at DESC")
    CSV.open(filename, "w", ";") do |writer|
      writer << ["id", "Título", "Fecha inicio", "Fecha fin", "Departamento", "Lugar"]
      events.each do |event|
        department = event.department.present? ? event.department.name : nil
        writer << [event.id, event.title, event.starts_at, event.ends_at, department, event.place]
      end
    end
    p "Export saved to #{filename}"
  end

end
