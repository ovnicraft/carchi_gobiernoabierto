# Cola de tweets enviados y por enviar. Se tweetean 
# * todas las noticias de Irekia coincidiendo con su fecha de publicación
# * todos los eventos  de Irekia 3 días antes de su comienzo
class DocumentTweet < ActiveRecord::Base
  # Cuentas disponibles en /config/secrets.yml
  # * <tt>irekia_devel:</tt> cuenta de pruebas
  # * <tt>irekia:</tt> cuenta para twittear a mano
  # * <tt>irekia_news:</tt> cuenta para el twitteo automático de noticias
  # * <tt>irekia_agenda:</tt> cuenta para el twitteo automático de eventos

  belongs_to :document

  scope :pending, ->(*args) { where(["tweet_at <= :now AND tweeted_at IS NULL AND tweet_account=:account", :now => Time.zone.now, account: args.first]).order("created_at")}

end
