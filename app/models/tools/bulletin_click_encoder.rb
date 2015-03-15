module Tools::BulletinClickEncoder
  def self.included(base)
    base.helper_method :encode_clickthrough
    base.helper_method :decode_clickthrough
  end
  
  # Clickthrough utilities
  # 
  # Builds a string to track clicks coming from a bulletin copy. The string contains information
  # of source bulletin copy and target object in the following format:
  # 
  # <:bulletin_copy_id>(z<:target_object_identifier><:target_id>)
  # 
  # [:bulletin_copy_id]
  #   The id of the bulletin copy the click came from, formatted in base35
  # [z]
  #   Constant separator of fields
  # [:target_object_identifier]
  #   Identifier to the Model the <tt>:target_id</tt> parameter is refering to. 
  #   See <tt>Bulletin::CONTENT_TYPES</tt> for a complete list of supported identifiers
  #   At the moment:
  # 
  #    identifier | Model     |  Description
  #   ------------+-----------+------------------
  #       n       |  News     |    For clicks from bulletin copies to News items
  #       d       |  Debate   |    For clicks from bulletin copies to Debate items
  #       b       | Bulletin  |    For clicks from bulletin copies to Web version of bulletins ("difficulty reading email?" link)
  #
  # [:target_id]
  #   The id of the Object the click is leading, formatted in base35
  #
  # The function takes 2 parameters:
  # [bulletin_copy]
  #   The object identifying the bulletin copy
  # [item]
  #   An optional object identifying the object the click should lead to. 
  #   If not provided, the "click" represents the opening of a bulletin in the client's
  #   email application, and should respond with the email header image 
  def encode_clickthrough(bulletin_copy, item=nil)
    if item.is_a?(News)
      "#{bulletin_copy.id.to_s(35)}zn#{item.id.to_s(35)}"
    elsif item.is_a?(Debate)
      "#{bulletin_copy.id.to_s(35)}zd#{item.id.to_s(35)}"
    elsif item.is_a?(BulletinCopy)
      "#{bulletin_copy.id.to_s(35)}zb#{item.id.to_s(35)}"
    else
      "#{bulletin_copy.id.to_s(35)}"
    end
  end
  # helper_method :encode_clickthrough
  
  # Takes a string encoded by #encode_clickthrough and returns a hash containing the following key/value pairs
  # [:bulletin_copy]
  #   The bulletin_copy_id where the use clicked. Always present.
  # [:content_type]
  #   The Object type of the item the user clicked. See Bulletin::CONTENT_TYPES for available types. Always present
  # [:content_id]
  #   The content_id of the item the user clicked. If not present, the click corresponds to the opening of a bulletin
  #   in the client's mail application
  #
  def decode_clickthrough(h)
    info = {}
    parts = h.split('z')
    if parts.length > 1
      parts.each_with_index do |part, index|
        if index == 0
          info[:bulletin_copy] = part.to_i(35)
        elsif index == 1
          content_type, content_id = part[0..0], part[1..-1]
          info[:content_type] = Bulletin::CONTENT_TYPES[content_type]
          info[:content_id] = content_id.to_i(35)
        end
      end
    else
      # Es la imagen que indica que ha abierto el boletin
      info[:bulletin_copy] = parts[0].to_i(35)
      info[:content_type] = "BulletinCopy"
    end
    return info
  end
  # / Clickthrough utilities
  
end
