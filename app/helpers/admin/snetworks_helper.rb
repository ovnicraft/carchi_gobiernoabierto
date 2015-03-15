# encoding: UTF-8
module Admin::SnetworksHelper
  
  def add_snetwork
    snet=Snetwork.new 
    html = render(:partial => '/admin/sorganizations/snetwork_form', :locals => {:snet => snet,:index => 'NEW_RECORD', :position => 'NEW_POSITION'})
    link_to('Añadir enlace', "#", :onclick => "$('snetwork_data').insert({ bottom: '#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()).replace(/NEW_POSITION/g, parseInt($$('tr.snetwork_data').last().down('input.position').value) +1) });return false;")
  end
  
  def remove_snetwork(f)
    if f.object.new_record?
      link_to('Eliminar', "#", :onclick => "$(this).up('.snetwork_data').remove();return false;")
    else
      f.hidden_field( :deleted, :value =>"0") + link_to('Eliminar', "#", :onclick => "$(this).up('.snetwork_data').hide();$(this).previous().value =1;return false;")
    end
  end
  
end  