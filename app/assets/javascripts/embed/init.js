/* Funciones que se usan desde le contenido del iframe incrustado en otras webs */

$(document).ready(function(){
  // Mostrar los enlaces desde los comentarios en ventana nueva.
  $('li.citizen_comment a').on('click', function(){
    window.open($(this).attr('href'), '_blank'); 
    return false;
  }); 
});

/* Login desde otra ventana.
//
// windows interaction references:
// http://dev.w3.org/html5/postmsg/#web-messaging
// https://developer.mozilla.org/en-US/docs/DOM/window.postMessage
//
*/
var windowLoginAction = {
  init: function(){
    if ($(".login-required").length > 0){
      $(".login-required").on("click.login_required", function(e){
        $elem = $(this);
        e.preventDefault();
        e.stopPropagation();

        var windowOptions = ["width=300", "height=600", "toolbar=no", "location=no", "directories=no", "status=no", "menubar=no", "scrollbars=yes", "copyhistory=no", "resizable=yes"];
        window.open($('#login_window_link').attr("href"), "loginWindow", windowOptions.join(","));        
      });
    }

    // Cuando la ventana de login envíe el mensaje __irekia_loggedin__:
    // 1.- Quitamos el evento click del botón submit porque el usuario ya está logeado.
    // 2.- Quitamos la clase login-required del botón submit
    // 3.- Enviamos el formulario.
    function submitComment() {
      $("#comment_submit").off("click"); // No funciona con IE8
      $("#comment_submit").removeClass("login-required");
      $("#new_comment").submit();
    }    

    function checkSenderAndSubmitComment(event) {
      var windowOrigin;
      if (typeof(window.location.origin) === "undefined") {
        // IE10
        windowOrigin = window.location.protocol + '//' + window.location.host;
      }
      else {
        windowOrigin = window.location.origin;
      }
        
      if ((event.origin === windowOrigin) && (event.data === "__irekia_loggedin__")) {
        submitComment();
      }    
    }
    // NOTA: $(window).on("message") no funciona correctamente.Por eso usamos addEventListener.
    // window.addEventListener('message', submitComment, false);

    if (window.addEventListener){
      window.addEventListener("message", checkSenderAndSubmitComment, false)
    } else {
      window.attachEvent("onmessage", checkSenderAndSubmitComment)
    }
  },
 
  // IE8 fix.
  // IE8 no puede llamar postMessage, por esto llama a esta función. 
  // Source: http://blogs.msdn.com/b/ieinternals/archive/2009/09/16/bugs-in-ie8-support-for-html5-postmessage-sessionstorage-and-localstorage.aspx
  logIn: function(message, senderLocation){
    if ((senderLocation.host == window.location.host) && (message == "__irekia_loggedin__")) {
      // 2DO: Hay que quitar el evento click del botón, pero .off no funciona con IE8
      $("#comment_submit").removeClass("login-required");
      $("#new_comment").submit();
    }
  }
};
