module InPlaceMacrosHelper
  
  def in_place_editor_with_autocompleter(field_id, options = {})
    function =  "new Ajax.InPlaceEditorWithAutocompleter("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"
    js_options = {}

    if protect_against_forgery?
      options[:with] ||= "Form.serialize(form)"
      options[:with] += " + '&authenticity_token=' + encodeURIComponent('#{form_authenticity_token}')"
    end
    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]    
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]       
 
    js_options['ajaxOptions'] = options[:options] if options[:options]
    js_options['htmlResponse'] = !options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['textBetweenControls'] = %('#{options[:text_between_controls]}') if options[:text_between_controls]
    
    js_options['onComplete'] = "function(form) { return #{options[:complete]} }" if options[:complete]
    
    js_options['inputID'] = %('#{options[:input_id]}') if options[:input_id]
    js_options['autocompleterUrl'] = %('#{options[:autocompleter_url]}') if options[:autocompleter_url]
    js_options['indicator'] = %('#{options[:indicator]}') if options[:indicator]

    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?
    
    function << ')'
    
    javascript_tag(function)
  end


  # Renders the value of the specified object and method with in-place and autocomplete editing capabilities.
  def in_place_editor_field_with_auto_complete(object, method, tag_options = {}, in_place_editor_options = {}, completion_options = {})
    # tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag = ::ActionView::Helpers::Tags::TextField.new(object, method, self)
    tag_options = {:nil_content_replacement => "--", :tag => "span", :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor", :class => "in_place_editor_field"}.merge!(tag_options)
    value = tag.object.send(method)
    if (value.blank?)
      value = tag_options.delete(:nil_content_replacement)
    end
    
    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :action => "set_#{object}_#{method}", :id => tag.object.id })
    in_place_editor_options[:cancel_text] ||= 'cancelar'
    in_place_editor_options[:click_to_edit_text] ||= 'click para modificar'
    in_place_editor_options[:loading_text] ||= 'leyendo ...'
    in_place_editor_options[:saving_text] ||= 'guardando ...'
    
    completion_options = completion_options.merge({:input_id => "#{object}_#{method}", :autocompleter_url => url_for(:action => "auto_complete_for_#{object}_#{method}", :id => tag.object.id)})
    
    tag.content_tag(tag_options.delete(:tag), value, tag_options) + 
    content_tag("div", "", :id => "#{object}_#{method}_auto_complete", :class => "auto_complete") +
    in_place_editor_with_autocompleter(tag_options[:id], in_place_editor_options.merge(completion_options))
  end

  
end