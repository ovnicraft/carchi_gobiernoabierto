# encoding: UTF-8
# Métodos adicionales para la clase String
class String

  # Convierte los caracteres UTF en su equivalente ASCII
  # (fuente http://www.bigbold.com/snippets/posts/show/1818)
  # Se utiliza para indexar textos sin tildes y hacer búsquedas de manera que
  # se encuentren los textos tanto si se escriben con o sin tildes
  def tildes
    foo = self.dup
    foo.gsub!(/[ĄÀÁÂÃ]/,'A')
    foo.gsub!(/[âäàãáäåāăǎǟǡǻȁȃȧẵặ]/,'a')
    foo.gsub!(/[ÉĘÈ]/, 'E')
    foo.gsub!(/[ëêéèẽēĕėẻȅȇẹȩęḙḛềếễểḕḗệḝ]/,'e')
    foo.gsub!(/[ÌÍÎĨÏ]/, 'I')
    foo.gsub!(/[iìíîĩīĭïỉǐịįȉȋḭɨḯ]/,'i')
    foo.gsub!(/[ÒÓÔÕÖ]/, 'O')
    foo.gsub!(/[òóôõōŏȯöỏőǒȍȏơǫọɵøồốỗổȱȫȭṍṏṑṓờớỡởợǭộǿ]/,'o')
    foo.gsub!(/[ÙÚÛŨÜ]/, 'U')
    foo.gsub!(/[ùúûũūŭüủůűǔȕȗưụṳųṷṵṹṻǖǜǘǖǚừứữửự]/,'u')
    foo.gsub!(/[ỳýŷỹȳẏÿỷẙƴỵ]/,'y')
    foo.gsub!(/[œ]/,'oe')
    foo.gsub!(/[ÆǼǢæ]/,'ae')
    foo.gsub!(/[ñǹńŃÑ]/,'n')
    foo.gsub!(/[ÇĆ]/, 'C')
    foo.gsub!(/[çć]/,'c')
    foo.gsub!(/[ß]/,'ss')
    foo.gsub!(/[œ]/,'oe')
    foo.gsub!(/[ĳ]/,'ij')
    foo.gsub!(/[Łł]/,'l')
    foo.gsub!(/[śŚ]/,'s')
    foo.gsub!(/ŹŻ/, 'Z')
    foo.gsub!(/[źż]/,'z')

    # El código anterior no quita bien los tildes cuando se usa IE :(
    # Uso este que quita todo lo que no es un símbolo ASCII
    foo_chars = []
    foo.each_byte {|i| foo_chars.push(i.chr) if i<127}
    foo_chars.join()
  end

  # Convierte un string en un tag, quitándole las tildes y quitando todo lo que no sea una letra, un número o una "_"
  # Si el tag empieza por #, sustituye "#" por "hashtag_" para evitar que
  # sanitized_name_* de un tag que empieza por "#" y otro que no tiene "#" coincidan.
  def to_tag
    return if self.nil?
    output = self.dup
    output = output.tildes.strip.downcase
    output.gsub(/^#/, 'hashtag_').gsub(/[^a-z0-9_]+/, '').gsub(/-+$/, '').gsub(/^-+$/, '')
  end

  # Quita de un texto todos los tags HTML
  def strip_html
    self.gsub(/<\/?[^>]*>/,  "")
  end

  # "Limpia" las palabras de búsqueda, quitándoles las tildes, quitando espacios de sobra y convirtiendo
  # en letras minúsculas
  def prepare_for_query
    # Esta la usamos allá donde los selects vayan a ser con "like 'xxx%'",
    # y por lo tanto, no queremos quitar ni los signos de puntuacion ni las
    # palabras comunes
    palabra = self

    # Primero quitamos las tildes
    search_string = palabra.tildes

    # Sustituimos muchos espacios por uno solo
    search_string = search_string.gsub(/[[:space:]]+/, " ")
    # Quitamos los espacios al principio y el final
    search_string = search_string.strip
    search_string = search_string.downcase
  end

  # Quita de un string, la versión.
  # Se usa para quitar la versión en las URL de las imágenes. Por ejemplo, transforma
  # <tt>/images/example.gif?388434738</tt> en <tt>/images/example.gif?388434738</tt>
  def strip_version
    self.sub(/\?\d+$/, '')
  end

  def gender_article
    name = self.dup.strip
    art = if name.match(/[a|ad]$/)
      "La"
    else
      "El"
    end
    art
  end

  def escape_for_elasticsearch(double_quotes=false)
    foo = self.dup
    foo.gsub!(/([\{\}\[\]\(\)\+\-\&\&\|\|\!\^\~\?\:\\\/])/, ' ')
    foo.gsub!(/([\"])/, '') if double_quotes
    foo
  end

  # enables query string syntax
  def escape_for_elasticsearch2
    foo = self.dup
    foo.gsub!(/([\{\}\[\]\^\/\\])/, ' ')
    foo
  end

end
