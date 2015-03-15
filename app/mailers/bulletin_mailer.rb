class BulletinMailer < ActionMailer::Base
  add_template_helper(DocumentsHelper)
  add_template_helper(SiteHelper)
  add_template_helper(ApplicationHelper)
  add_template_helper(ProposalsHelper)
  add_template_helper(BulletinsHelper)
  include Tools::BulletinClickEncoder

  layout "bulletin_mailer"#, :except => [:announce]

  default from: "#{Settings.site_name} <#{Settings.email_addresses[:from].split(',').first}>"

  def copy(bulletin_copy)
    @bulletin_copy = bulletin_copy
    mail(to: bulletin_copy.user.bulletin_email, subject: "#{Bulletin.model_name.human}: #{bulletin_copy.bulletin.title}", content_type: "text/html")
  end

  def announce(user)
    @user = user
    # subject    = "#{Settings.site_name}: #{I18n.t('bulletin_mailer.announcement_title', :locale => user.alerts_locale)}"
    mail(to: "#{user.public_name} <#{user.bulletin_email}>", content_type: "text/html", subject: "#{Settings.site_name}: #{Settings.site_name} Buletina / Boletín de #{Settings.site_name}")
  end
end
