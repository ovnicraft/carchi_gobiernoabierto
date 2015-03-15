# Clase para las notificaciones por email
class Notifier < ActionMailer::Base
  add_template_helper(CommentsHelper) # I need method url_to_commentable in notifier views

  default from: "#{Settings.site_name} <#{Settings.email_addresses[:from].split(',').first}>"

  def password_reset(user)
    @user = user
    mail(to: user.email, subject: I18n.t('notifier.password_reset.subject', :site_name => Settings.site_name))
  end

  # Enviar por email una noticia a un amigo
  def email_document(sender_name, recipient_name, recipient_email, document)
    @sender_name = sender_name
    @recipient_name = recipient_name
    @document = document
    mail(to: recipient_email, subject: "#{I18n.t('share.te_recomienda', :site_name => Settings.site_name, :sender_name => sender_name)}")
  end

  # Formulario de contacto
  def contact(sender_name, sender_email, message)
    @sender_name = sender_name
    @sender_email = sender_email
    @message = message
    mail(to: Settings.email_addresses[:contact].split(',').collect(&:strip), reply_to: "#{sender_name} <#{sender_email}>", subject: I18n.t('notifier.contact_subject', :site_name => Settings.site_name))
  end

  # Email de bienvenida a un periodista. Se envía al aprobar a un periodista,
  # y se le manda la contraseña que se le acaba de generar
  def welcome_journalist(user)
    @user = user
    mail(to: user.email, subject: "#{I18n.t('notifier.welcome', :name => Settings.site_name, :locale => user.alerts_locale)}")
  end

  # Confirmación de identidad de un usuario. Se le envía un email con enlace para activar su cuenta
  def activate_person_account(user)
    @user = user
    mail(to: user.email, subject: "#{I18n.t('notifier.welcome', :name => Settings.site_name)}")
  end

  # Email de alerta de evento para periodistas
  def journalist_event_alert(event_alert)
    @event_alert = event_alert
    @event_title = @event_alert.event.send("title_#{event_alert.spammable.alerts_locale}").present? ? @event_alert.event.send("title_#{event_alert.spammable.alerts_locale}") : @event_alert.event.title
    subject = case @event_alert.exists_previous_sent_alert?
               when true
                 "[#{Settings.site_name}] #{I18n.t('notifier.cambios_en')} \"#{@event_title}\""
               else
                 "[#{Settings.site_name}] #{@event_title}"
               end

    unless event_alert.event.deleted?
      event_ics = RiCal.Calendar do |cal|
        cal.add_x_property('X-WR-CALNAME',"#{Settings.site_name}::Eventos")
        event_alert.event.to_ics(cal) {{:url => event_url(event_alert.event, locale: I18n.locale)}}
      end
      attachments["event#{event_alert.event_id}.ics"] = {
        mime_type: "text/calendar",
        content: event_ics.to_s
      }
    end

    mail(to: event_alert.spammable.email, subject: subject)
  end

  # Email de alerta de evento con streaming, para responsable de sala o operador de streaming
  def staff_event_alert(event_alert)
    locale = event_alert.spammable.respond_to?("alerts_locale") ? event_alert.spammable.alerts_locale : "es"
    title = event_alert.event.send("title_#{locale}").present? ? event_alert.event.send("title_#{locale}").tildes : event_alert.event.title.tildes
    event_title = event_alert.event.send("title_#{event_alert.spammable.alerts_locale}").present? ? event_alert.event.send("title_#{event_alert.spammable.alerts_locale}") : event_alert.event.title

    subject = event_alert.exists_previous_sent_alert? ? "#{I18n.t('notifier.cambios_en')} " : ""
    if event_alert.spammable.is_a?(DepartmentEditor) || event_alert.spammable == event_alert.event.creator
      subject << "\"#{event_title}\""
    else
      subject << I18n.t('notifier.notificacion_sobre_streaming', :para => event_title, :locale => locale)
    end

    unless event_alert.event.deleted?
      event_ics = RiCal.Calendar do |cal|
        cal.add_x_property('X-WR-CALNAME',"#{Settings.site_name}::Eventos")
        @event_alert = event_alert
        event_alert.event.to_ics(cal) {
          {:url => url_for(:controller => "/sadmin/events", :action => "show", :id => event_alert, :only_path => false, :host => ActionMailer::Base.default_url_options[:host]),
           :description => render("staff_event_alert.html")}
        }
      end
      attachments["event#{event_alert.event_id}.ics"] = {
        mime_type: "text/calendar", 
        content: event_ics.to_s
      }
    end

    mail(to: event_alert.spammable.email, subject: subject)
  end

  # Email que avisa a un comentarista de que su comentario ha sido rechazado
  def comment_rejected(comment)
    @comment = comment
    mail(to: comment.user.email, subject: "#{I18n.t('notifier.comment_rejected.subject', :site_name => Settings.site_name)}")
  end

  def comment_answer(comment, previous_commenter)
    @item = comment.commentable
    @commenter = previous_commenter
    mail(to: previous_commenter.email, subject: "#{I18n.t('notifier.comment_answer.subject', :site_name => Settings.site_name, :locale => 'eu')} / #{I18n.t('notifier.comment_answer.subject', :site_name => Settings.site_name, :locale => 'es')}")
  end  

  def new_proposal(proposal)
    @proposal = proposal
    mail(to: Proposal::MODERATORS, subject: "Nueva propuesta en #{Settings.site_name}")
  end

  def proposal_organization(proposal)
    @proposal = proposal
    department = proposal.organization.department
    recipients = department.department_editors.collect(&:email) + department.department_members_official_commenters.collect(&:email)
    mail(to: recipients, subject: "Nueva propuesta en #{Settings.site_name}")
  end

  def proposal_approval(proposal)
    @proposal = proposal
    mail(to: proposal.user.email, subject: "#{I18n.t('notifier.proposal_approval.subject', :site_name => Settings.site_name, :locale => "eu")}/#{I18n.t('notifier.proposal_approval.subject', :site_name => Settings.site_name, :locale => "es")}")
  end

  # Email que avisa a un comentarista de que su propuesta ha sido rechazado
  def proposal_rejection(proposal)
    @proposal = proposal
    mail(to: proposal.user.email, subject: "#{I18n.t('notifier.proposal_rejection.subject', :locale => "eu")}/#{I18n.t('notifier.proposal_rejection.subject', :locale => "es")}")
  end

  def proposal_answer(proposal, participant)
    @proposal = proposal
    @participant = participant
    mail(to: participant.email, subject: "#{I18n.t('notifier.proposal_answer.subject', :site_name => Settings.site_name, :locale => 'eu')} / #{I18n.t('notifier.proposal_answer.subject', :site_name => Settings.site_name, :locale => 'es')}")
  end

  def orphan_videos_alert(videos)
    @videos = videos
    mail to: Settings.email_addresses[:orphan_videos_responsibles].split(',').collect(&:strip),
         subject: "Revisión de vídeos de la WebTV"
  end
end
