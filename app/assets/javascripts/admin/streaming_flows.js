//
// Funciones para la administración de los streamiing flows.
//

// Comprobar que está elegida alguna de las opciones del evento que se va a emitir.
// Si no hay ninguna opción elegida se muestra un mensaje de error.
function sfEventOptionIsSelected(sf_form_id) {
  var checked = 0;
  var event_div = $(sf_form_id).up('div').down('div.sf_event_options');
    
  if (typeof(event_dir) != "undefined") {
    event_div.removeClassName('with_errors');
    event_div.down('span.error_notice').hide();

  
    $(sf_form_id).getInputs().each(function(inp) {
      if (inp.hasClassName('event_radio')) { 
        if (inp.checked) {
          checked = 1;
        }
      }
    });
  
    if (checked === 0) {
      $(sf_form_id).getInputs().each(function(inp) {
        if (inp.hasClassName('event_radio')) { 
          inp.enable();
        }
      });
      event_div.addClassName('with_errors');
      event_div.down('span.error_notice').show();
    }
  } else {
    checked = 1;
  }

  return (checked > 0);
}

// Mostrar/esconder las opciones de un streaming flow dependiendo del evento elegido.
function sfSetOptions(selected_event) {
	var sf_tr = $(selected_event).up("td");
	var webs = $(selected_event).attributes["web"].value.split(",")
	
	sf_tr.descendants().each(function(elem) {
	  if (elem.type === 'submit') {
		elem.addClassName('hidden_option');
		webs.each(function(web) {
		  if (elem.id.match(web)) {
			  elem.removeClassName('hidden_option');
		  }
		});
	  } 
	});  
}

function sfDisableRadioIfOnWeb() {
  $$("div.streaming_status").each(function(elem){
    var td_elem = elem.up("td");    
    var disable_radio = (td_elem.hasClassName('show_in_irekia') || td_elem.hasClassName('announced_in_irekia'));
    
    $$("div#"+elem.id+" input.event_radio").each(function(r){
      if (typeof(r) != "undefined") {
        if (disable_radio) {
          r.disable();
        }
        else {
          r.enable();          
        }
      }
    });
  });  
}

Event.observe(window, 'load', function(evt) {
  $$("input.event_radio").each(function(r) {
    Event.observe(r, 'click', function(event){ sfSetOptions(event.element()) });
  });
  
  $$("div.streaming_status").each(function(elem){
    $$("div#"+elem.id+" input.event_radio").each(function(r){
      if (typeof(r) != "undefined") {
        if (r.checked) {
          sfSetOptions(r);
        } 
      }
    });
  });
  
  sfDisableRadioIfOnWeb();

});

// Mostrar los botones correspondientes al hacer click en el enlace "ver botones"
function sfShowButtons(evt) {
  var elem = evt.element();
  var data_div = elem.up("div");

  data_div.descendants().each(function(elem) {
    if (elem.type === 'submit') {
      elem.removeClassName('hidden_option');
    }
  });
  elem.hide();
  evt.stop();
}

Event.observe(window, 'load', function(evt) {
  $$("span.show_options_link").each(function(elem){
    Event.observe(elem, 'click', sfShowButtons);
  });
})


// Inicializar los players.

MaPlayers = [];

function initPlayers(evt) {

  $$("a.player").each( function(strm) {
    var foto = $$("a#"+strm.id+" img").first();
    if (foto != undefined) {
      foto = foto.src;
    } else {
      foto = Irekia.hostWithPort+"/assets/video_preview.jpg";
    }

    // Asignar el código del streaming como href del enlace.
    // El flowplayer usa el href del enlace para coger el código del streaming.
    // Pero si el href se pone en el HTML y el visitante pincha en él antes de
    // que el flowplayer este inicializado, seguirá el enlace.
    // Por esto ponemos el código del streaming como data-streaming_code
    // y lo asignamos como href justo antes de inicializar el player.
       
    strm.setAttribute("href", strm.getAttribute("data-streaming_code"));
    
    MaPlayers.push(initStreamingPlayer(strm, {foto:foto, autoPlay:'false'}));    
   
    // // get the embedding code 
    // var code = MaPlayers.last().embed().getEmbedCode().gsub('https://', 'http://'); 
    // 
    // // place this code in our textarea 
    // document.getElementById("textarea_"+strm.id).innerHTML = code;     
  });
  
}

Event.observe(window, "load", initPlayers);


// Mostrar los botones correspondientes al hacer click en el enlace "ver botones"
function sfShowManagers(evt) {
  var elem = evt.element();
  var data_div = elem.siblings("div.managers")[0];
  data_div.toggle();
  evt.stop();
}
Event.observe(window, 'load', function(evt) {
  $$('div.room_managers a').each(function(a) {
    Event.observe(a, 'click', sfShowManagers);
  });
})