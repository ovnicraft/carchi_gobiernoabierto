$(document).ready(function() {
  
  $('select.selectpicker').selectpicker({style: 'irekia_btn'});
  
  TrackItem.init();
  
  if($('div.search_container.new').length > 0) {
    $('div.search_container.new form').find('input[name=value]').focus();
  }
  
  var $overlay = $('#overlay');
  $('div.results').delegate('a.explanation_link', 'click', function(e){
    e.preventDefault();
    var overlay_content = $(this).parent('div').siblings('.explanation_content').html();
    $overlay.html(overlay_content).show();
  })
  
})
