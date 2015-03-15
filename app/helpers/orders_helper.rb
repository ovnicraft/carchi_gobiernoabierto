# encoding: UTF-8
module OrdersHelper
  
  # Truncar el texto sin cortar palabra a medias
  def smart_truncate(text, length = 255)        
    if text.present? && text.length > length            
      words = text.split(' ')
      i = 0
      output = String.new
      while output.length < length && i < (words.length - 1) do
        output << "#{words[i]} "
        i += 1
      end  
      output.gsub!(/\W?\s$/, "&hellip;")
    else
      output = text  
    end
    output.html_safe
  end
  
  def show_order_ref_with_links(reference)         
    output = []    
    reference.split(';').each do |ref|
      foo=ref.match(/([A-Z]+ )*(\d{9})/)
      unless foo.nil?
        bar=foo[2].match(/(\d{4})0*(\d*)/)
        output << content_tag(:li, ref.gsub(foo[0], link_to(foo[0], search_orders_url(:key => 'keyword', :value => "#{foo[1]} #{bar[2]}/#{bar[1]}"), :method => :post)).gsub(/(\[\d+\])\z/, '').html_safe)        
      else
        foo=ref.match(/\[(\d+)\]\z/)
        unless foo.nil?
          bar=foo[1].match(/(\d{4})0*(\d*)/)
          foo2=ref.match(/\w+ ([^\s]+ de [0-9]+\/[0-9]+\/[0-9]+)/)
          unless foo2.nil?
            output << content_tag(:li, ref.gsub(foo2[1], link_to(foo2[1], search_orders_url(:key => 'keyword', :value => "#{foo2[1].split.first} #{bar[2]}/#{bar[1]}"), :method => :post)).gsub(/(\[\d+\])\z/, '').html_safe)
          else
            output << content_tag(:li, ref.html_safe)  
          end  
        else
          output << content_tag(:li, ref.html_safe)  
        end  
      end  
    end     
    content_tag(:ul, output.join.html_safe)
    # output.join('<br />')
  end
  
  def show_order_attributes_with_links(order, attribute)
    output = []                                   
    locales = ['es', 'eu']                                                                                       
    key = attribute.eql?('dept') ? 'organo' : attribute
    values_es = order.send("#{attribute}_es").present? ? order.send("#{attribute}_es").split(';') : []
    values_eu = order.send("#{attribute}_eu").present? ? order.send("#{attribute}_eu").split(';') : []
    order.send(attribute).split(';').each_with_index do |value, i|
      output << link_to(value, search_orders_url(:key => key, :value => "#{values_es[i]}|#{values_eu[i]}|#{values_es[i]}"), :method => :post)
    end                                   
    output.join('; ').html_safe
  end  
  
  # 
  # def show_order_dept_with_links(order)
  #   output = []                                   
  #   locales = ['es', 'eu']
  #   depts_es = order.dept_es.split(';')
  #   depts_eu = order.dept_eu.split(';')
  #   order.dept.split(';').each_with_index do |dept, i|
  #     output << link_to(dept, search_orders_url(:key => 'organo', :value => "#{depts_es[i]}|#{depts_eu[i]}|#{depts_es[i]}"), :method => :post)
  #   end                                   
  #   output.join('; ')
  # end                                                          
  # 
  # def show_order_materias_with_links(order)
  #   output = []                                   
  #   locales = ['es', 'eu']
  #   materias_es = order.materias_es.split(';')
  #   materias_eu = order.materias_eu.split(';')
  #   order.materias.split(';').each_with_index do |dept, i|
  #     output << link_to(dept, search_orders_url(:key => 'materias', :value => "#{materias_es[i]}|#{materias_eu[i]}|#{materias_es[i]}"), :method => :post)
  #   end                                   
  #   output.join('; ')
  # end 
  
  def show_order_texto_with_links(text)                                                                   
    if I18n.locale.to_s.eql?('eu')
      reg_exp1 = /(\d{1,}\/\d{4}) (Erabakia|Iragarkia|Agindua|Dekretua|Dekretoa|Ediktua|Akordioa|Legea|Foru arua|Foru agindua|Foru dekretua|Eskumen gatazka positiboa|Zirkularra|Legegintz dekretua|Legegintza dekretua|Legegintza-dekretoa|Dekreto-legea|Errege dekretua)/i
      # reg_exp2 = /(\d{4})(.?e?ko)? (urtarrila|otsaila|martxoa|apirila|maiatza|ekaina|uztaila|abuztua|iraila|urria|azaroa|abendua)(ren)? (\d{1,})(e?ko)? (Erabakia|Iragarkia|Agindua|Dekretua|Dekretoa|Ediktua|Akordioa|Legea|Foru arua|Foru agindua|Foru dekretua|Eskumen gatazka positiboa|Zirkularra|Legegintz dekretua|Legegintza dekretua|Legegintza-dekretoa|Dekreto-legea|Errege dekretua)/i
      reg_exp2 = ""
    else
      reg_exp1 = /(Resolución|Anuncio|Orden|Decreto|Edicto|Acuerdo|Ley|Norma Foral|Orden Foral|Decreto Foral|Conflicto Positivo de Competencia|Circular|Decreto legislativo|Decreto ley|Real decreto|Recurso de inconstitucionalidad|Cuestión de inconstitucionalidad) (\d{1,}\/\d{4})/i
      reg_exp2 = /(Resolución|Anuncio|Orden|Decreto|Edicto|Acuerdo|Ley|Norma Foral|Orden Foral|Decreto Foral|Conflicto Positivo de Competencia|Circular|Decreto legislativo|Decreto ley|Real decreto|Recurso de inconstitucionalidad|Cuestión de inconstitucionalidad) (de \d{1,} de) (enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre) (de \d{4})/i
    end    
    output = text.gsub(reg_exp1){|m| link_to(m, search_orders_url(:key => 'keyword', :value => m), :method => :post)}
    output = output.gsub(reg_exp2){|m| link_to(m, search_orders_url(:key => 'keyword', :value => m), :method => :post) } if reg_exp2.present?  
    output.html_safe
  end                                        
  
  def show_order_texto_hightlighted_with_links(text, criterio) 
    text = sanitize(text)
    if criterio.present?
      show_order_texto_with_links(highlight_according_to_criterio(text, criterio))
    else  
      show_order_texto_with_links(text)
    end        
  end                                                         
  
end  