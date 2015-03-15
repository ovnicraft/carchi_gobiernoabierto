# Métodos comunes para los controller que incrustan información en otras webs.
class Embed::BaseController < ApplicationController
  layout "embed"

  skip_before_filter :http_authentication
  before_filter :set_embed_layout
  #
  # Si sale algún error al cargar una acción de controllers que heredan Embed::BaseController
  # devolver una página vacía con status 593 (Error HTTP 503 Service unavailable)
  # Así si el request corresponde a src de un iframe, en el iframe no saldrá nada.
  #
  rescue_from Exception, :with => :render_empty_document

  private
  def render_empty_document(exception)
    email_notifier = ExceptionNotifier.registered_exception_notifier(:email)
    email_notifier.call(exception)

    service_unavailable()
  end

  def set_embed_layout
    @embed_layout = true
  end

end
