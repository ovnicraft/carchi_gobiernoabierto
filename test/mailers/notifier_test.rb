require 'test_helper'

class NotifierTest < ActionMailer::TestCase

  test "should email password reset" do
    I18n.locale = :eu
    user = users(:visitante)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      user.send_password_reset
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [user.email], email.to
    assert_equal I18n.t('notifier.password_reset.subject', :site_name => Settings.site_name), email.subject
    assert_match "klika ezazu ondoko esteka", email.body.to_s
    assert_match "#{ActionMailer::Base.default_url_options[:host]}/eu/password_resets/#{user.password_reset_token}/edit", email.body.to_s
    I18n.locale = :es
  end

  test "should email document to a friend" do
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.email_document("Remitente", "Receptor", "receptor@efaber.net", documents(:one_news)).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal ['receptor@efaber.net'], email.to
    assert_equal I18n.t('share.te_recomienda', :sender_name => "Remitente", :site_name => Settings.site_name), email.subject
    assert_match 'Remitente ha pensado que te interesará leer esta página', email.body.to_s
  end

  test "should email contact to #{Settings.email_addresses[:contact]}" do
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.contact("Remitente", "receptor@efaber.net", 'foo message').deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [Settings.email_addresses[:from].split(',').first], email.from
    assert_equal Settings.email_addresses[:contact].split(',').collect(&:strip), email.to
    assert_equal I18n.t('notifier.contact_subject', :site_name => Settings.site_name), email.subject
    assert_match 'foo message', email.body.to_s
  end

  test "should welcome journalist" do
    user = users(:periodista_sin_aprobar)
    assert_equal true, user.update_attribute(:alerts_locale, 'eu')
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.welcome_journalist(user).deliver
    end

    email = ActionMailer::Base.deliveries.last

    assert_equal ['periodista_sin_aprobar@efaber.net'], email.to
    assert_equal I18n.t('notifier.welcome', :name => Settings.site_name, :locale => 'eu'), email.subject
    assert_match 'Zure erregistroa aktibatuta dago.', email.body.to_s
  end

  test "should send account activation email in spanish" do
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.activate_person_account(users(:visitante_sin_activar)).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal ['visitante_sin_activar@efaber.net'], email.to
    assert_equal I18n.t('notifier.welcome', :name => Settings.site_name), email.subject
    assert_match 'Para asegurarnos de que realmente has solicitado el alta en', email.body.to_s
  end

  test "should send account activation email in basque" do
    I18n.locale = :eu
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.activate_person_account(users(:visitante_sin_activar)).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal ['visitante_sin_activar@efaber.net'], email.to
    assert_equal I18n.t('notifier.welcome', :name => Settings.site_name, :locale => "eu"), email.subject
    assert_match 'alta eskatu duzula, zure kontua aktiba dezazun behar dugu.', email.body.to_s
    I18n.locale = :es
  end

 if Settings.optional_modules.streaming
  test "should send email in spanish to room_manager of event with streamingaaaaaa" do
    ea = event_alerts(:unsent_alert_for_room_manager_of_event_with_streaming)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.staff_event_alert(ea).deliver
    end

    email = ActionMailer::Base.deliveries.last
    # Test the body of the sent email contains what we expect it to
    # This journalist has requested alerts in spanish, but the event title is not available but in spanish
    assert_equal ['manager@efaber.net'], email.to
    assert_equal "Streaming para #{ea.event.title}", email.subject

    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match 'desde Lehendakaritza te informamos', part.body.to_s
        assert_match "Fecha: #{ea.event.pretty_dates('es')}", part.body.to_s
        assert_match "desde #{ea.event.stream_flow.title} y se emitirá en #{ea.event.streaming_for_pretty}", part.body.to_s
        assert_no_match /#{I18n.t('events.irekia_coverage', :site_name => Settings.site_name, :cov_types => "")}/, part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end
  test "for event without streaming and sent alert live_streaming does notify about existing streaming" do
    event = documents(:event_with_sent_alert)
    # already has a sent alert
    assert event.alerts.sent.exists?({:spammable_id => users(:periodista_con_alertas).id})
    event.streaming_live = true
    event.stream_flow_id = stream_flows(:sf_two).id
    event.streaming_for = 'irekia'
    assert_difference 'event.alerts.unsent.where("spammable_id=#{users(:periodista_con_alertas).id}").count', +1 do
      assert_equal true, event.save
    end
    new_alert = event.alerts.unsent.where("spammable_id=#{users(:periodista_con_alertas).id}").first
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.journalist_event_alert(new_alert).deliver
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match I18n.t('notifier.event_streaming_live_true'), part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end

  test "for event without streaming and sent alert changing starts_at does not notify about existing streaming" do
    event = documents(:event_with_sent_alert)
    # already has a sent alert
    assert event.alerts.sent.exists?({:spammable_id => users(:admin).id})
    event.starts_at = event.starts_at - 1.hour
    assert_difference 'event.alerts.unsent.where("spammable_id=#{users(:admin).id}").count', +1 do
      event.save!
    end
    new_alert = event.alerts.unsent.where("spammable_id=#{users(:admin).id}").first
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.staff_event_alert(new_alert).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert email.body !~ /I18n.t('notifier.event_streaming_live_true')/
  end


  test "for event with streaming does notify about existing streaming" do
    event = documents(:event_with_streaming_and_sent_alert_and_show_in_irekia)
    event.streaming_live = false
    assert_difference 'event.alerts.unsent.where("spammable_id=#{users(:operador_de_streaming).id}").count', +1 do
      assert_equal true, event.save!
    end
    new_alert = event.alerts.unsent.where("spammable_id=#{users(:operador_de_streaming).id}").first
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.staff_event_alert(new_alert).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match I18n.t('notifier.event_streaming_live_false'), part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end

  test "should send email in spanish to creator of event with streaming" do
    ea = event_alerts(:unsent_alert_for_creator_of_event_with_streaming)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.staff_event_alert(ea).deliver
    end

    email = ActionMailer::Base.deliveries.last
    # Test the body of the sent email contains what we expect it to
    # This journalist has requested alerts in spanish, but the event title is not available but in spanish
    assert_equal ['admin@efaber.net'], email.to
    assert_equal "\"#{ea.event.title}\"", email.subject

    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match 'desde Lehendakaritza te informamos', part.body.to_s
        assert_match "Fecha: #{ea.event.pretty_dates('es')}", part.body.to_s
        assert_match I18n.t('notifier.event_streaming_live_true'), part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end

  test "should send email in spanish to streaming operator of event with streaming" do
    ea = event_alerts(:unsent_alert_for_streaming_operator_of_event_with_streaming)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.staff_event_alert(ea).deliver
    end

    email = ActionMailer::Base.deliveries.last
    # Test the body of the sent email contains what we expect it to
    # This journalist has requested alerts in spanish, but the event title is not available but in spanish
    assert_equal ['operador@efaber.net'], email.to
    assert_equal "Streaming para #{ea.event.title}", email.subject

    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match 'desde Lehendakaritza te informamos', part.body.to_s
        assert_match "Fecha: #{ea.event.pretty_dates('es')}", part.body.to_s
        assert_match "desde #{ea.event.stream_flow.title} y se emitirá en #{ea.event.streaming_for_pretty}", part.body.to_s
        assert_no_match /#{I18n.t('events.irekia_coverage', :site_name => Settings.site_name, :cov_types => "")}/, part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end


  test "alert about event with streaming should contain info about room" do
    ea = event_alerts(:unsent_alert_for_streaming_operator_of_event_with_streaming)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.staff_event_alert(ea).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match "desde #{ea.event.stream_flow.title} y se emitirá en #{ea.event.streaming_for_pretty}", part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end
 end

  test "should send email in spanish to journalist about event published" do
    # Send the email, then test that it got queued
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.journalist_event_alert(event_alerts(:unsent_alert)).deliver
    end
    email = ActionMailer::Base.deliveries.last

    # Test the body of the sent email contains what we expect it to
    # This journalist has requested alerts in spanish
    assert_equal ['periodista2@efaber.net'], email.to
    assert_equal "[#{Settings.site_name}] #{event_alerts(:unsent_alert).event.title_es.tildes}", email.subject
    # assert_match 'Alerta sobre evento en', email.body
    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match 'Por la presente desde Lehendakaritza te informamos que el evento', part.body.to_s
        assert_match "Fecha: #{event_alerts(:unsent_alert).event.pretty_dates('es')}", part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end

  test "email in spanish to journalist about event published should contain speakers text in spanish" do
    UserActionObserver.current_user = users(:admin)
    evt = event_alerts(:unsent_alert).event
    politician_tag = tags(:tag_politician_lehendakaritza)
    politician = Politician.find(politician_tag.kind_info)
    speaker = 'Otro invitado'
    evt.update_attributes(:tag_list => politician_tag.name, :speaker_es => speaker)
    assert_equal "#{politician.public_name_and_role}, #{speaker}", evt.attendee_names
    UserActionObserver.current_user = nil

    # Send the email, then test that it got queued
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.journalist_event_alert(event_alerts(:unsent_alert)).deliver
    end

    email = ActionMailer::Base.deliveries.last
    # Test the body of the sent email contains what we expect it to
    # This journalist has requested alerts in spanish
    assert_equal ['periodista2@efaber.net'], email.to
    assert_equal "[#{Settings.site_name}] #{event_alerts(:unsent_alert).event.title_es.tildes}", email.subject
    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match "#{I18n.t('events.speaker', :locale => 'es')}: #{evt.attendee_names}", part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end

  test "should send email in basque to journalist about event published" do
    event_alert = event_alerts(:unsent_alert_eu)
    # Send the email, then test that it got queued
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.journalist_event_alert(event_alert).deliver
    end

    email = ActionMailer::Base.deliveries.last
    # Test the body of the sent email contains what we expect it to
    # This journalist has requested alerts in spanish, but the event title is not available but in spanish
    assert_equal ['periodista_eu@efaber.net'], email.to
    assert_equal "[#{Settings.site_name}] #{event_alert.event.title_es.tildes}", email.subject
    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match 'Azpiko ekitaldiaren inguruan', part.body.to_s
        assert_match "Data: #{event_alerts(:unsent_alert).event.pretty_dates('eu')}", part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end

  test "email in basque to journalist about event published should contain speakers text in basque" do
    event_alert = event_alerts(:unsent_alert_eu)
    UserActionObserver.current_user = users(:admin)
    evt = event_alert.event
    politician_tag = tags(:tag_politician_lehendakaritza)
    politician = Politician.find(politician_tag.kind_info)
    speaker_es = 'Otro invitado'
    speaker_eu = 'Bestea'
    evt.update_attributes(:tag_list => politician_tag.name, :speaker_es => speaker_es, :speaker_eu => speaker_eu)
    I18n.locale = :eu
    assert_equal "#{politician.public_name} (#{politician.public_role_eu}), Bestea", evt.attendee_names
    I18n.locale = :es
    UserActionObserver.current_user = nil

    email_locale = event_alert.spammable.alerts_locale
    assert_equal 'eu', email_locale

    # Send the email, then test that it got queued
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.journalist_event_alert(event_alert).deliver
    end

    email = ActionMailer::Base.deliveries.last
    # Test the body of the sent email contains what we expect it to
    # This journalist has requested alerts in basque
    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match 'Azpiko ekitaldiaren inguruan', part.body.to_s
        assert_match "#{I18n.t('events.speaker', :locale => 'eu')}: #{evt.attendee_names('eu')}", part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end

  test "should send email in spanish to journalist on event only for photographers" do
    ea = EventAlert.create(:event => documents(:event_with_tag_one), :spammable_id => users(:periodista_con_alertas).id, :spammable_type => 'Journalist', :version => 1, :send_at => Time.zone.now - 30.minutes)

    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.journalist_event_alert(ea).deliver
    end

    email = ActionMailer::Base.deliveries.last
    # Test the body of the sent email contains what we expect it to
    # This journalist has requested alerts in spanish, but the event title is not available but in spanish
    assert_equal [users(:periodista_con_alertas).email], email.to
    assert_equal "[#{Settings.site_name}] #{documents(:event_with_tag_one).title_es.tildes}", email.subject.tildes

    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match 'Por la presente desde Lehendakaritza te informamos que el evento', part.body.to_s
        assert_match "Fecha: #{ea.event.pretty_dates('es')}", part.body.to_s
        assert_match "es sólo para medios gráficos", part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end


  test "should send email in spanish to creator of event with draft realed_news" do
    ea = EventAlert.create(:event => documents(:emakunde_future_event), :spammable_id => users(:jefe_de_prensa).id, :spammable_type => 'DepartmentEditor', :version => 1, :send_at => Time.zone.now - 30.minutes, :notify_about => 'coverage')
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.staff_event_alert(ea).deliver
    end

    email = ActionMailer::Base.deliveries.last
    # Test the body of the sent email contains what we expect it to
    # This journalist has requested alerts in spanish, but the event title is not available but in spanish
    assert_equal [users(:jefe_de_prensa).email], email.to
    assert_equal "\"#{ea.event.title}\"", email.subject

    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match 'desde Lehendakaritza te informamos', part.body.to_s
        assert_match "Fecha: #{ea.event.pretty_dates('es')}", part.body.to_s
        assert_match "BORRADOR inicial", part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end


  test " staff alert should contain info about attendee" do
    ea = event_alerts(:unsent_alert_for_room_manager)

    UserActionObserver.current_user = users(:admin)
    evt = ea.event
    politician_tag = tags(:tag_politician_lehendakaritza)
    politician = Politician.find(politician_tag.kind_info)
    speaker = 'Otro invitado'
    evt.update_attributes(:tag_list => politician_tag.name, :speaker_es => speaker)
    assert_equal "#{politician.public_name_and_role}, #{speaker}", evt.attendee_names
    UserActionObserver.current_user = nil

    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.staff_event_alert(ea).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal 2, email.body.parts.length
    email.body.parts.each do |part|
      if part.content_type.eql?('text/html; charset=UTF-8')
        assert_match "#{I18n.t('events.speaker', :locale => 'es')}: #{evt.attendee_names}", part.body.to_s
      elsif part.content_type.eql?('text/calendar; charset=UTF-8')
        assert_not_nil part.body.to_s
      end
    end
  end

  test "comment rejected" do
    comment = comments(:rechazado_castellano)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.comment_rejected(comment).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [comment.user.email], email.to
    assert_equal I18n.t('notifier.comment_rejected.subject', :site_name => Settings.site_name), email.subject
  end

  test "comment answer" do
    comment = comments(:aprobado_castellano)
    previous_commenter = comment.user
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.comment_answer(comment, previous_commenter).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [previous_commenter.email], email.to
    assert_equal "#{I18n.t('notifier.comment_answer.subject', :site_name => Settings.site_name, :locale => 'eu')} / #{I18n.t('notifier.comment_answer.subject', :site_name => Settings.site_name, :locale => 'es')}", email.subject
  end

 if Settings.optional_modules.proposals
  test "new proposal" do
    proposal = proposals(:unapproved_proposal)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.new_proposal(proposal).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal Proposal::MODERATORS, email.to
    assert_equal "Nueva propuesta en #{Settings.site_name}", email.subject
  end

  test "proposal organization" do
    proposal = proposals(:interior_proposal)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.proposal_organization(proposal).deliver
    end

    email = ActionMailer::Base.deliveries.last

    department = proposal.organization.department
    recipients = department.department_editors.collect(&:email) + department.department_members_official_commenters.collect(&:email)
    assert_equal recipients, email.to
    assert_equal "Nueva propuesta en #{Settings.site_name}", email.subject
  end

  test "proposal approval" do
    proposal = proposals(:approved_and_published_proposal)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.proposal_approval(proposal).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [proposal.user.email], email.to
    assert_equal "#{I18n.t('notifier.proposal_approval.subject', :site_name => Settings.site_name, :locale => "eu")}/#{I18n.t('notifier.proposal_approval.subject', :site_name => Settings.site_name, :locale => "es")}", email.subject
  end

  test "proposal rejection" do
    proposal = proposals(:rejected_proposal)
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.proposal_rejection(proposal).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [proposal.user.email], email.to
    assert_equal "#{I18n.t('notifier.proposal_rejection.subject', :locale => "eu")}/#{I18n.t('notifier.proposal_rejection.subject', :locale => "es")}", email.subject
  end

  test "proposal answer" do
    proposal = proposals(:interior_proposal)
    participant = proposal.user
    assert_difference 'ActionMailer::Base.deliveries.count', +1 do
      Notifier.proposal_answer(proposal, participant).deliver
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [participant.email], email.to
    assert_equal "#{I18n.t('notifier.proposal_answer.subject', :site_name => Settings.site_name, :locale => 'eu')} / #{I18n.t('notifier.proposal_answer.subject', :site_name => Settings.site_name, :locale => 'es')}", email.subject
  end
 end

  test "blocked_lock_file" do
    # TODO
  end

end
