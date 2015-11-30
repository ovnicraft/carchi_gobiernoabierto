$(document).ready(function(){
  $('.share_popover').click(function(e){e.preventDefault()}).popover({
    html: true, 
    placement: 'right',
    content: $('.share_links').html(), 
    afterShow: function(){
      $('.popover-content').on('click', '.email', function(){
        $('#send_email').modal();
        setEmailValidation();
      });
      externalLinksToTargetBlank(); 
    }
  });

  // copy to clipboard
  if ($('.copy_to_clipboard').length > 0) {
    var clip = new ZeroClipboard($("a.copy_to_clipboard"));
    $("a.copy_to_clipboard").on("click", function(){
      $(this).siblings('.copied').fadeIn(200).fadeOut(100);
      return false;
    });
  }
})

function setEmailValidation(){
  $('div.share_button form').on('submit', function(e){
    $(this).find('div.control-group').removeClass('error');
    $(this).find('input.validate').each(function(){
      if ($(this).val().length === 0 || ($(this).attr('type') === 'email' && $(this).val().match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/) === null)) {
        $(this).parents('div.control-group').addClass('error');
        e.preventDefault();
      }
    });
  });  
}
