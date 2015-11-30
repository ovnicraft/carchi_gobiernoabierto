// Extend popover with afterShow callback
var tmp = $.fn.popover.Constructor.prototype.show;
$.fn.popover.Constructor.prototype.show = function () {
 tmp.call(this);
 if (this.options.afterShow) {
    this.options.afterShow();
 }
}

var toggleSearchForm = {
  init: function(){
    $that=$(this)
    var $label = $('nav .search_label');
    var $form = $('nav .search_form');
    if ($label.length > 0){
      $label.on('click', this.toggleForm);
      // $form.find('input[type=text]').on('blur', this.toggleForm);
    } 
  },
  toggleForm: function(e){
    e.preventDefault();
    var $label = $('nav .search_label');
    var $form = $('nav .search_form');
    $label.toggle();
    $form.toggle();
    if ($form.find('input#value').is(':visible')) {
      $form.find('input#value').focus();
    }
  }
}

// Load dropdown remote content via ajax
$.fn.loadRemoteContent = function (){
  return this.each(function() {
    $(this).on('click.remote', function(e) {
      e.preventDefault();
      $elem = $(this);
      if ($elem.filter('.dropdown-remote').not('.loaded')){
        $.ajax({
          url: $elem.data('source'),
          dataType: 'html',
          success: function(data, textStatus, jqXHR){
            $elem.addClass('loaded').unbind('click.remote');
            $elem.siblings('.dropdown-menu').find('.dropdown-menu-content').html(data);
            // toreview: ensure it keeps on working
            // with unobtrusive javascript we can't stop propagation because it will 
            // prevent unobtrusive javascript from changing the hyperlink method to post.
            // $elem.siblings('.dropdown-menu').find('a').on('click', function(e){
            //   e.stopPropagation();
            // });
          },
          error: function(jqXHR, status, error){
            window.location = $elem.attr('href');
          }
        });
      } else {
        return false;
      }
    });  
  });
}

// Spinner
var Spinner = {
  show: function($elem){
    $elem.find('.btn_with_spinner').append($('#iddle_container').html());
  },
  hide: function($elem){
    $elem.find('div.spinner').remove();
  }
};

// Not used -> changed to windowLoginAction
// Launch Modal Login and Default Action
// var modalLoginAction = {
//   init: function(){
//     if ($('.login-required').length > 0){
//       is_logged_in = false;
//       // form_params = "";
//       $('.login-required').on('click.login_required', function(e){
//         $elem = $(this);
//         if (!is_logged_in) {
//           e.preventDefault();
//           $('#login_modal_link').click();
//           $('#modal_login').on('hidden', function(){
//             // NOTA: is_logged_in es una variable global! 
//             // Su valor cambia después de login, ver loginForm.init()
//             if (is_logged_in){
//               $elem.unbind('click.login_required');
//               if ($elem.is('input')) {
//                 $elem.click();  
//               } else {
//                 window.location = $elem.attr('href');
//               }
//             }
//           });
//         }
//       });
//     }
//   }
// }

var windowLoginAction = {
  init: function(){
    $elem = '';
    if ($(".login-required").length > 0){
      $(".login-required").on("click.login_required", function(e){
        $elem = $(this);
        $elem.addClass('login_required_clicked');
        e.preventDefault();
        e.stopPropagation();

        var windowOptions = ["width=300", "height=600", "toolbar=no", "location=no", "directories=no", "status=no", "menubar=no", "scrollbars=yes", "copyhistory=no", "resizable=yes"];
        window.open($('#login_window_link').attr("href"), "loginWindow", windowOptions.join(","));        
      });

      if (window.addEventListener){
        window.addEventListener("message", function(e){
         windowLoginAction.checkSenderAndDoAction(e, $elem) 
        }, false);
      } else {
        window.attachEvent("onmessage", function(e){
         windowLoginAction.checkSenderAndDoAction(e, $elem) 
        }, false);
      }
    }

    // function submitComment() {
    //   $("#comment_submit").off("click"); // No funciona con IE8
    //   $("#comment_submit").removeClass("login-required");
    //   $("#new_comment").submit();
    // }    

    // function checkSenderAndDoAction(event, elem) {
    //   if (event.origin === window.location.protocol + '//' + window.location.host) {
    //     if (event.data === "__irekia_loggedin__") {
    //       elem.removeClass('login_required_clicked');
    //       elem.unbind('click.login_required');
    //       updateUserNavInfo();
    //       elem.click();  
    //     } else {
    //       var locale = window.location.pathname.split('/')[1]
    //       if (event.data === "__irekia_register__") {
    //         var new_location = '/people/new';
    //         if (elem.hasClass('subscription')) {
    //           new_location = new_location.concat('?subscription=1')
    //         }
    //       } else if (event.data === "__irekia_pswd_reset__") {
    //         var new_location = '/password_resets/new';
    //       }
    //       window.location = '/' + locale + new_location;  
    //     }
    //   } 
    // }

    

  },
 
  // IE8 fix.
  logIn: function(message, senderLocation){
    var event = new Object();
    event.data = message;
    event.origin = senderLocation.protocol + '//' + senderLocation.host;
    var $elem = $('.login_required_clicked').first();
    windowLoginAction.checkSenderAndDoAction(event, $elem);
  },

  checkSenderAndDoAction: function(event, elem) {
    if (event.origin === window.location.protocol + '//' + window.location.host) {
      if (event.data === "__irekia_loggedin__") {
        elem.removeClass('login_required_clicked');
        elem.unbind('click.login_required');
        windowLoginAction.updateUserNavInfo();
        elem.click();  
      } else {
        var locale = window.location.pathname.split('/')[1]
        if (event.data === "__irekia_register__") {
          var new_location = '/people/new';
          if (elem.hasClass('subscription')) {
            new_location = new_location.concat('?subscription=1')
          }
        } else if (event.data === "__irekia_pswd_reset__") {
          var new_location = '/password_resets/new';
        }
        window.location = '/' + locale + new_location;  
      }
    } 
  },

  updateUserNavInfo: function(){
    $.ajax({
      url: '/es/nav_user_info',
      dataType: 'html',
      success: function(data, textStatus, jqXHR){
        $('nav#nav_top ul li').slice(-2).remove();  
        $('nav#nav_top ul').append(data);
      },
      error: function(){
        // don't do anything
      }
    });
  }
};

// Form Errors 
var formErrors = {
  init: function() {
    if ($('form #has-errors').length > 0){
      var error = $.parseJSON($('#has-errors').text());
      var klass = $('#has-errors').data('class');
      this.highlight(error, klass);
    }
  },
  highlight: function(error, klass){
    $('.error-messages').show();
    for (var i in error){
      $elem = $('#' + klass + '_' + error[i][0]);
      $elem.parents('.control-group').addClass('error');
      if (error[i][1] != undefined) {
        $elem.parents('.controls').append("<span class='help-inline help-error'>" + error[i][1] + "</span>");   
      }
    }
  },
  clear: function(){
    $('.error-messages').hide();
    $('.control-group').removeClass('error');
    $('.help-error').remove();
  }
}


// LoginForm: bind all events to handle errors, user info and more
var loginForm = {
  init: function(){
    $form = $('form.login');
    $form.find('input:visible:first').focus();
    $form.on('ajax:beforeSend', function(e){
      Spinner.show($form);
      formErrors.clear();
    }).on('ajax:complete', function(e){
      Spinner.hide($form);
    }).on('ajax:success', function(e, jqXHR, options){
      is_logged_in = true;
      is_modal = $form.parents().hasClass('modal');
      if (is_modal) {
        $('#modal_login').modal('hide');
        // change nav_bar_top html to logged_in part
        $.ajax({
          url: '/es/nav_user_info',
          dataType: 'html',
          success: function(data, textStatus, jqXHR){
            $('nav#nav_top ul li').slice(-2).remove();  
            $('nav#nav_top ul').append(data);
          },
          error: function(){
            // don't do anything
          }
        })
      } else {
        location.reload();  
      }
    }).on('ajax:error', function(e, jqXHR, status, error){
      formErrors.highlight($.parseJSON(jqXHR.responseText), 'user');
    });
  }
}

// Following form: bind all events
var followingForm = {
  init: function(){
    var $form = $('form.follow_button');
    $form.on('ajax:beforeSend', function(e){
      Spinner.show($form);
    }).on('ajax:complete', function(e){
      Spinner.hide($form);
    }).on('ajax:success', function(e, jqXHR, options){
      $form.replaceWith(jqXHR);
    }).on('ajax:error', function(e, jqXHR, options){
      $form.replaceWith(jqXHR.responseText);
      $form.effect("shake", {times: 4}, 100);
    });
  }
}

var TrackItem = {
  init: function () {
    if($('div.results').length > 0) {
      $('div.results').first().find('div.title').each(function(){ 
        var rawLink = $(this).find('a').attr('href');
        if (rawLink.match(/\?/) == null) {
          new_href = rawLink + '?track=1' 
        } else {
          new_href = rawLink + '&track=1'
        }
        $(this).find('a').attr('href', new_href);
      });
    }
  }
}

// Comment Form 
var commentForm = {
  form: $('form.add_comment'),
  init: function(){
    $form=this.form;
    disableIfEmpty($('#comment'), $form.find('input[type=submit]'));
    $form.on('ajax:beforeSend', function(e){
      commentForm.clearInfo();
      Spinner.show($(this));
    }).on('ajax:complete', function(e){
      Spinner.hide($(this));
    }).on('ajax:success', function(e, jqXHR, options){
      commentForm.insert(jqXHR);
      $form.trigger("reset");
    }).on('ajax:error', function(e, jqXHR, options){
      var errorText;
      // If the responseText matches HTML it is a server error and gener error mesage is shown.
      // Otherwise the response text is shown.
      if (jqXHR.responseText.match("html")) {
        errorText = "<li class='info'><div class='alert alert-error'>Errore bat egon da. Mesedez, saia zaitez berriro beranduago.<br/>Ha habido un error. Por favor, inténtelo más tarde.</div></li>";
      } else {
        errorText = $.parseJSON(jqXHR.responseText);
      }
      
      commentForm.insert(errorText); 
    });
  },
  insert: function(content){
    $form=this.form;
    $form.parents("ul").find("li.form").after(content);
  },
  clearInfo: function(content){
    $form=this.form;
    $next_elem=$form.parents("ul").find("li.info");
    if ($next_elem.length > 0 ) {
      $next_elem.remove();  
    }
  }

}

var alertsLocale = {
  init: function () {
    this.toggleAlertsRadioButtons();
    $('.requires_alerts_locale').bind('click', this.toggleAlertsRadioButtons);
  },
  toggleAlertsRadioButtons: function () {
    if ($('.requires_alerts_locale').length > 0) {
      var alerts_locale_required = ($('.requires_alerts_locale').map (function () {return $(this).is(':checked')}).index(true) != -1)
      if (alerts_locale_required) {
        $('#alerts_locale_container').show();
      } else {
        $('#alerts_locale_container').hide();
      }
    }
  }
}
// Filter content by area
var areaFilter = {
  init: function() {
    if ($('form#area_filter').length > 0){
      var $form = $('form#area_filter');
      var $select = $form.children('select');

      $select.selectpicker({style: 'irekia_btn'}); // bootstrap-select
      
      $select.on('change', function () {
        $(this).closest("form").submit();
      });
      
      // Replace news list when filtering by area
      $form
      .on('ajax:beforeSend', function() {
        Spinner.show($form.parents('ul'));
      })
      .on('ajax:success', function(event, xhr, settings) {
        $('#filtered_content').fadeOut(1000, function() { 
          $(this).replaceWith(xhr).fadeIn(1000);
        });
      })
      .on('ajax:complete', function() {
        Spinner.hide($form.parents('ul'));
      });
    }
  }
}

var calendarNavigation = {
  init: function(){
    if ($('.calendar').length > 0) {
      $('.calendar a.change_month').on('click', function(e){
        e.preventDefault();
        $link = $(this);
        $calendar = $link.parents('.calendar');
        $.ajax({
          dataType: 'html',
          url: $(this).attr('href'),
          beforeSend: function(){
            calendarNavigation.toggleLoading($calendar);
          },
          success: function(data, textStatus, jqXHR){
            $calendar.replaceWith(data);
          },
          complete: function(){
            calendarNavigation.toggleLoading($calendar);
          }
        })
      })
    }
  },
  toggleLoading: function(elem){
    elem.find('.loading_overlay').toggle();
  }
}

function showEmbedCodePhotoVideoViewer(embed_link) {
  var embed_container = $(embed_link).parent().siblings('div.embed_container');
  $(embed_container).slideToggle();
  $(embed_container).find('textarea').focus();
  $(embed_container).find('textarea').select();
}

function disableIfEmpty($input, $submit){
  $input.on('keyup keydown', function(e){
    $(this).val().length > 0 ? $submit.prop('disabled', false) : $submit.prop('disabled', true);
  });
}

function toggleWelcomeSlide() {
  $('div#welcome_slide').toggle();
  $('div#intro').toggle();
}

function remove_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest("div.attachment").hide();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  $(link).before(content.replace(regexp, new_id));
}

function externalLinksToTargetBlank(){
  $('a[rel*=external]').on('click', function(){
    window.open($(this).attr('href'), '_blank'); 
    return false;
  }); 
}
