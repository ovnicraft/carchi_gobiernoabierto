$(document).ready(function(){

  externalLinksToTargetBlank();

  // Disable nav click when li.disabled
  if ($('ul.nav-tabs').length > 0){
    $('ul.nav-tabs li.disabled a').click(function(e){
      return false;
    });
  }

  // Stop dropdown toggle propagation when click in a, input, label
  if ($('.dropdown-menu').length > 0) {
    $('.dropdown-menu').find('input, label, a').on('click', function(e){
      e.stopPropagation();
    });
  }

  // Navbar top
  toggleSearchForm.init();
  $('.dropdown-remote').loadRemoteContent();

  // Highlight errors in all forms
  formErrors.init();

  // Modal login and default action
  // modalLoginAction.init();
  windowLoginAction.init();

  // Area filter used in news, events, proposals and answers list
  areaFilter.init();

  // Shows or hides alerts locale preference fields depending on the user's will to receive any
  alertsLocale.init();

  // Carousel
  if ($('.carousel').length > 0){
    if ($('.dynamic_carousel').length > 0){
      $('.dynamic_carousel').carousel({interval: 20000});
    }
    $('.carousel').carousel({interval: false});
  }

  /////////////// ADMIN ///////////////

  // Load CouchDB Stats
  if ($('#stats').length > 0){
    $('#stats').on('ajax:beforeSend', function(e){
      Spinner.show($(this).parents('.admin_links'));
    }).on('ajax:complete', function(e){
      Spinner.hide($(this).parents('.admin_links'));
    }).on('ajax:success', function(e, jqXHR, options){
      $('#stats_container').html(jqXHR);
    });
  }

  // Rate related news and orders
  if ($('span.rate_related').length > 0){
    $('span.rate_related').delegate('a', 'click', function(e){
      e.preventDefault();
      var target=$(this);
      $parent = target.parents('span.rate_related')
      Spinner.show($parent);
      $.post($(this).attr('href'), function(data){
        Spinner.hide($parent);
        target.parents('span.rate_related').append('OK!');
        if (target.hasClass('good')) {
          var increment = 1.0;
        } else {
          var increment = -1.0;
        }
        $total_rating = target.siblings('span.total_rating');
        current_val=parseFloat($total_rating.text().match(/\((.*)\)/)[1]);
        current_val = isNaN(current_val) ? increment : current_val + increment;
        // current_val = current_val + increment;
        $total_rating.text("(" + current_val + ")");
      });
    });
  }

});
