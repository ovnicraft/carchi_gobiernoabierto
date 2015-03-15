$(document).ready(function(){

  var participationActions = {
    init: function(){
      $('.new_argument').each(function(){
        disableIfEmpty($(this).find('textarea'), $(this).find('input[type=submit]'));
      })
      $('#votes form, #participation_arguments form').on('submit', function(e){
        e.preventDefault();
        var $form = $(this);
        $.ajax({
          type: 'POST',
          url: $form.attr('action'),
          data: $form.serialize(),
          dataType: 'html',
          beforeSend: function(){
            Spinner.show($form);
          },
          complete: function(){
            Spinner.hide($form);
          },
          success: function(data, textStatus, jqXHR){
            if ($form.parents('[id*=participation_arguments]').length > 0) {
              $form.parent().prev('ul').append(data);
            } else {
              $('#votes').replaceWith(data);
            }
            $form.trigger('reset');
          },
          error: function(){
            $form.effect("shake", {times: 4}, 100);
          }
        });
      });
    }
  }

  participationActions.init();
})
