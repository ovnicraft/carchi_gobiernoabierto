/*
** Streamings en Irekia: anunciados y emitiéndose.
**
** Usamos promises, http://api.jquery.com/deferred.promise/
*/

var irekiaStreaming = function(){
  var streamingStatusObserver = {
         "announced": $.Deferred(),
         "live": $.Deferred()
      },
      self = this,
      currentStatus, // El estado actual del streaming
      interval = 0,  // tiempo restante hasta el comienzo del evento
      statusURL,     // URL donde consultar el estado actual del streaming
      streamingURL,  // URL que devuelve el HTML que corresponde al estado del streaming
      container,     // selector para el DOM que contiene el HTML que cambia cuando cambia el estado del streaming.
      timeoutID;


  var streaming = {

    /* Setter y getter para currentStatus del streaming */
    currentStatus: function(value) {
      if (!arguments.length) return currentStatus;
      currentStatus = value;
      return this;
    },

    /* Setter y getter para la URL donde hay que consultar el status del streaming */
    statusURL: function(value) {
      if (!arguments.length) {
        d = new Date;
        return statusURL+"?"+d.getTime(); // IE hack to prevent GET request result caching
      }

      statusURL = value;
      return this;
    },

    /* Setter y getter para la URL que devuelve el HTML que corresponde al estado del streaming */
    streamingURL: function(value) {
      if (!arguments.length) return streamingURL;
      streamingURL = value;
      return this;
    },

    /* Setter y getter para el intervalo de tiempo hasta el comienzo el evento */
    interval: function(value) {
      if (!arguments.length) return interval;
      interval = parseInt(value, 10)*1000;
      if (interval < 0) {
        interval = 0;
      }
      return this;
    },

    /* Setter y getter para el selector del DOM element donde sale el HTML que corresponde al estado del streaming */
    container: function(value) {
      if (!arguments.length) return container;
      container = value;
      return this;
    },

    /*
    ** Iniciar la comprobación periodica del estado del streaming.
    **
    ** Si el streaming está anunciado,
    ** cuando empieza la emisión, se sustituye la foto del anuncio por el player.
    **
    ** Si el streaming está en directo,
    ** cuando deja de emitirse, se cambia el player por el texto "La emisión ha terminado"
    **
    ** NOTA: Es imprescindible llamar esta función después de asignar valores a:
    ** currentStatus, statusURL, streamingURL, container e interval.
    */
    init: function() {
      // console.info("Init "+currentStatus+" streaming ....");

      $.when(streamingStatusObserver[currentStatus]).done(changeContainerContent).progress(scheduleNextCheck).fail(reloadPage);

      // Dentro de un intervalo aleatorio después de @interval@, comprobamos el estado del streaming.
      // max 100 segundos si (interval === 0)
      var timeoutInterval = this.interval() + Math.floor(Math.random()*100)*1000;
      setTimeout("checkStreamingStatus()", timeoutInterval);

      // console.info("Comporbar el estado por primera vez dentro de "+timeoutInterval+" milisec")

      return this;
    },

  };

  /* Métodos privados */

  /*
  ** Comprobar el estdo del streaming.
  ** Si ha cambiado el estado del streaming llama el método resolve() del deferred.
  ** Si todavía no hay cambio, llama al método notify() del deferred.
  */
  checkStreamingStatus = function() {
    // console.info("Send ajax request GET "+streaming.statusURL()+" to check if streaming has started");
    // console.info("Current status: "+currentStatus);

    var newStatus = currentStatus;

    $.get( streaming.statusURL(), function( data ) {
      // console.info("received data: "+data);

      if (currentStatus === "live") {
        if (data.match("show_irekia_off")) {
          // console.info("Finished");
          streamingStatusObserver[currentStatus].resolve();
          newStatus = "finished";
        } else if (!data.match("show_irekia_on")) {
          streamingStatusObserver[currentStatus].reject();
        }
      }

      if (currentStatus === "announced") {
        if (data.match("show_irekia_on")) {
          // console.info("Start streaming");
          streamingStatusObserver[currentStatus].resolve();
          newStatus = "live";
        } else if (data.match("show_irekia_off")) {
          // console.info("Finished");
          streamingStatusObserver[currentStatus].resolve();
          newStatus = "finished";
        }
      }

      if (streamingStatusObserver[currentStatus].state() === "pending") {
        // console.info("Still waiting ....");
        streamingStatusObserver[currentStatus].notify("waiting");
      }

      currentStatus = newStatus;

    });

    return self;
  },


  /*
  ** Programar la siguiente comprobación dentro de un intervalo de tiempo "aleatorio".
  */
  scheduleNextCheck = function() {
    // console.info("Schedule next request ....")

    var timeoutInterval = (Math.floor(Math.random()*90)+30)*1000; // max 120 seg., min 30 seg.
    timeoutID = setTimeout("checkStreamingStatus()", timeoutInterval);

    // console.info("Check streaming status in "+timeoutInterval+" milisec.");

    return self;
  }


  /*
  ** Sustituir el HTML con el anuncio por el player.
  */
  changeContainerContent = function() {
    // console.info("GET streaming HTML from "+streamingURL);

    $.get( streamingURL, function( data ) {
      $(container).html( data );
    });

    return self;
  }

  reloadPage = function() {
    location.reload();
  }

  return streaming;
}
