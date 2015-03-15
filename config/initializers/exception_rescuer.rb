module ExceptionRescuer
  def email_exception
    begin
      yield
    rescue => e
      email_notifier = ExceptionNotifier.registered_exception_notifier(:email)
      if email_notifier.nil?
        email_notifier = ExceptionNotifier::EmailNotifier.new(EXCEPTION_NOTIFIER_OPTIONS)
      end
      email_notifier.call(exception)

      logger.info("******* ERROR *******: There were some errors : " + e.to_s)
      # flash[:error] = t('session.Error_servidor_correo')
    end
  end
end
