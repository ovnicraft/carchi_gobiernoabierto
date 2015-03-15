# Módulo para las clases en las que se quiere que las URL contengan el título
# y no sólo el id.
module Sluggable
  # Sobreescribe el método to_param para incluir el título además del id.
  def to_param
    # Quitar todo lo que no sea letra o numero
    words = title.to_s.tildes.strip.downcase.gsub(/[^a-z0-9]+/, ' ').split
    # Sin palabras de 1 o 2 letras
    long_words = words.collect {|w| w if w.length>2}.compact
    short_name = long_words.join('-')
    # short_name = short_name[0..60].sub(/-[^-]+$/, '') unless short_name.length <= 60 # Quitamos desde el final hasta el - anterior para no cortar palabras
    # Quitar guiones al principio o a final
    short_name = short_name.gsub(/-+$/, '').gsub(/^-+/, '')
    "#{id}-#{short_name}"
  end
end