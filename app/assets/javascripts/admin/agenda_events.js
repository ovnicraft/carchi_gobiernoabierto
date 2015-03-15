/*
* Functions for the event create/edit form.
* eli@efaber.net, 24-08-2009
*/


// Global variable IrekiAGENDA to hold Agenda specific global variables.
var IrekiAGENDA = {
    ends_at_changed: false,
    end_hour_changed: false
}


function setEndsAtChanged(e) {
    IrekiAGENDA.ends_at_changed = true;
    setEventHasExpired();
}

function setEndHourChanged(e) {
    IrekiAGENDA.end_hour_changed = true;
    setEventHasExpired();
}

// Visibilidad

// Marcar un evento como privado, descheckea las opciones de periodistas
function checkPrivateEvent() {
  if ($("event_is_private__1")) {
    $("event_is_private__1").checked = true;
    uncheckPublicEvent();
  }
}

function uncheckPrivateEvent() {
  $("event_is_private__1").checked = false;
}

// Elegimos la opción evento público y marcamos la opción 'para todos los periodistas'
function checkPublicEvent() {
  enableAlertable();
}

// Desmarcamos la ópción de evento publico junto con las de los periodistas
function uncheckPublicEvent() {

  disableAlertable();

}

// Marcar la opción "todos los periodistas"
function checkAllJournalists() {
  $("event_is_private_0").checked= true;
  $("event_alertable").checked= true;
  $("event_all_journalists").checked = true;
  uncheckOnlyPhotographers();
}

// Desmarcar "todos los periodistas"
function uncheckAllJournalists() {
  $("event_all_journalists").checked = false;
}

// Marcar la opción "sólo fotógrafos" muestra el texto con la explicación y desmarca la opción "todos los periodistas"
function checkOnlyPhotographers() {
  $("event_is_private_0").checked= true;
  var elem = $("event_only_photographers");
  elem.checked = true;
  elem.up().down("div").show();
  $("event_all_journalists").checked = false;
}

// Desmarcar la opción "sólo fotográfos" esconde la explicación
function uncheckOnlyPhotographers() {
  var elem = $("event_only_photographers");
  elem.checked = false;
  elem.up().down("div").hide();
}



// Por defecto un evento es privado
function setDefaultVisibility() {
  if ($("event_is_private__1")) {
    checkPrivateEvent();
  }
}

function enableAlertThisChange () {
  $("event_alert_this_change").checked = true;
  $('alert_this_change_container').removeClassName('disabled');
  $("event_alert_this_change").removeClassName('disabled');
  $("event_alert_this_change").enable();
}

function disableAlertThisChange () {
  $("event_alert_this_change").checked = false;
  if (!$('event_is_private_0').checked) {
    $("event_alert_this_change").addClassName('disabled');
    $("event_alert_this_change").disable();
  }
}

function enableAlertable() {
  $('event_alertable').disabled = false;
  $$('li.alert_option').each(function(elem) {
    elem.removeClassName('disabled');
    elem.down("input").enable();
  });
  enableAlertThisChange();

  checkAllJournalists();
  enableAlertThisChange();
}

function disableAlertable () {
  $('event_alertable').checked = false;
  $('event_alertable').disabled = !$('event_is_private_0').checked ;
  $$('.alert_option').each(function(elem) {
    elem.addClassName('disabled');
    elem.down("input").disable();
  });

  uncheckAllJournalists();
  uncheckOnlyPhotographers();
  disableAlertThisChange();
}

function setEventHasExpired() {
  var new_start_hour = new Date(parseInt($("event_ends_at_1i").value),
                                parseInt($("event_ends_at_2i").value - 1),
                                parseInt($("event_ends_at_3i").value),
                                parseInt($("event_ends_at_4i").value),
                                parseInt($("event_ends_at_5i").value));

  if (new_start_hour > Date.now()) {
    EventAlerts.event_has_expired = false;
  } else {
    EventAlerts.event_has_expired = true;
  }
  setMustConfirm();
}

function setEventFieldsObserver(e) {



    function setEndsAtValues(e) {
        var elem_to_check = Event.element(e).id.replace("starts_at", "ends_at")
        var change_it = true;

        if (IrekiAGENDA.ends_at_changed && ($(elem_to_check).value >= Event.element(e).value)) {
            change_it = false;
        }

        if (change_it) {
            $(elem_to_check).value = Event.element(e).value;
            IrekiAGENDA.ends_at_changed = false;
            IrekiAGENDA.end_hour_changed = false;
        }
    }

    function setEndHourValues(e) {
        var change_it = !IrekiAGENDA.end_hour_changed && !IrekiAGENDA.ends_at_changed;

        if (change_it) {

            var starts_at = {
                hour:   parseInt($("event_starts_at_4i").value.replace(/^0/,'')),
                minute: parseInt($("event_starts_at_5i").value)
            }

            var ends_at = {
                hour:   parseInt($("event_ends_at_4i").value.replace(/^0/,'')),
                minute: parseInt($("event_ends_at_5i").value)
            }

            ends_at.hour = starts_at.hour;
            ends_at.minute = starts_at.minute + 30;

            if (ends_at.minute >= 60) {
                ends_at.hour += 1;
                ends_at.minute -= 60;
            }
            for (name in ends_at) {
                if (ends_at[name] < 10) {
                    ends_at[name] = "0"+ends_at[name];
                }
            }

            $('event_ends_at_4i').value = ends_at.hour;
            $('event_ends_at_5i').value = ends_at.minute;
            IrekiAGENDA.end_hour_changed = false;
        }

    }

    if ($('event_starts_at_1i')) {
        // Date fields observers
        for (var i=1; i<=3; i++) {
            Event.observe('event_starts_at_'+i+'i', 'change', setEndsAtValues);
            Event.observe('event_ends_at_'+i+'i', 'change', setEndsAtChanged);
        }

        // Time fields observers
        for (var i=4; i<=5; i++) {
            Event.observe('event_starts_at_'+i+'i', 'change', setEndHourValues);
            Event.observe('event_ends_at_'+i+'i', 'change', setEndHourChanged);
        }
    }

    if ($('event_is_private__1')) {
      Event.observe('event_is_private__1', 'click', function(e) {
        checkPrivateEvent();
      });
    }

    if ($('event_is_private_0')) {
      Event.observe('event_is_private_0', 'click', function(e) {
        checkPublicEvent();
        setMustConfirm(e);
      });
    }

    if ($('event_all_journalists')) {
      Event.observe('event_all_journalists', 'click', function(e) {
        if (Event.element(e).checked) {
          checkAllJournalists();
        }
      });
    }

    if ($('event_only_photographers')) {
      Event.observe('event_only_photographers', 'click', function(e) {
        if (Event.element(e).checked) {
          checkOnlyPhotographers();
        } else {
          uncheckOnlyPhotographers();
        }
      });
    }
    if ($('event_alertable')) {
      Event.observe('event_alertable', 'click', function(e) {
        if (Event.element(e).checked) {
          enableAlertable();
        } else {
          disableAlertable();
        }
        setMustConfirm(e);

      });
    }

    if ($('event_alert_this_change')) {
      Event.observe('event_alert_this_change', 'click', function(e) {
        if (Event.element(e).checked) {
           $("event_alertable").checked = true;
        }
        setMustConfirm(e);
      });
    }

    $$("div.is_private_radio_options input.schedule_radio").each(function(elem){
      Event.observe(elem.id, 'click', function(e) {
        setMustConfirm(e);
      });
    });
}

Event.observe(window, 'load', setEventFieldsObserver)

var EventAlerts = {
    has_sent_alerts: false,
    must_confirm: false,
    confirm_message: "",
    saving_message: "",
    event_is_confirmed_and_shown: true,
    event_has_expired: false
}

function checkForConfirmation(e) {
    if (!confirmAndDisable(Event.element(e), EventAlerts.must_confirm, EventAlerts.confirm_message, EventAlerts.saving_message)) {
        e.stop();
    }
}


function setMustConfirm(e) {
    if (EventAlerts.event_has_expired) {
      EventAlerts.must_confirm = false;
    } else {
        EventAlerts.must_confirm = EventAlerts.has_sent_alerts;
        if ($('event_alertable')) {
            EventAlerts.must_confirm = EventAlerts.must_confirm || $('event_alertable').checked;
            if ($('event_alert_this_change')) {
              EventAlerts.must_confirm = EventAlerts.must_confirm && $('event_alert_this_change').checked;
            }
        }
        if ($('document_streaming_live')) {
            EventAlerts.must_confirm = EventAlerts.must_confirm || (EventAlerts.event_is_confirmed_and_shown && $('document_streaming_live').checked && $('document_irekia_coverage').checked);
        }
    }
    setWarningVisibility();
}

function setWarningVisibility() {
    if ($('warning')) {
        EventAlerts.must_confirm ? $('warning').show() : $('warning').hide();
    }
}

function setSubmitWarningVisibility(e) {
    setWarningVisibility();
    $$('input.submit_button').each (function(btn) {Event.observe(btn, 'click', checkForConfirmation);})

    $A(['event_confirmed', 'document_streaming_live', 'document_irekia_coverage']).each (function(el) {
        if ($(el)) {Event.observe($(el), 'click', setMustConfirm)};
    })

    // Mostrar el warning si cambia la sala de streaming.
    $$("input.sf_radio").each (function(el) {
        Event.observe($(el), 'click', setMustConfirm);
    });

    // Mostrar el warning si cambia la ventana de emisión.
    $$("input.sf_for").each (function(el) {
        Event.observe($(el), 'click', setMustConfirm);
    });
}

function setEventPlaceValues(elem, value) {
    var city = $A(value.childElements()).find(function(e) {
        if (e.className === "city") {
            return e;
        }
    });
    var address = $A(value.childElements()).find(function(e) {
        if (e.className === "address") {
            return e;
        }
    });

    $("event_city").value = city.innerHTML;
    $("event_location_for_gmaps").value = address.innerHTML;
}

Event.observe(window, "load", setSubmitWarningVisibility);

Event.observe(window, "load", setAlertableFields);

function setAlertableFields () {
  // console.log('en setAlertableFields');
  if ($('event_is_private_0') != null) {
    if (!$('event_is_private_0').checked) {
      disableAlertable();
    }
  }
}

// Event's streaming related functions. Used when a streaming room is assigned to an event.
function checkForOverlapFlow(evt) {
    elem = Event.element(evt);
    setFlowOverlapInfo(elem);
}

function setFlowOverlapInfo(elem) {
    Irekia.overlapEvents.each(function(oe){
        if (parseInt(elem.value, 10) === parseInt(oe.stream_flow_id, 10)) {
            $("overlap_info_"+oe.stream_flow_id).innerHTML = "AVISO: Coincide con el evento: " + oe.title;
        } else {
            $("overlap_info_"+oe.stream_flow_id).innerHTML = "";
        }
    });
}

function checkForOverlapWeb(evt) {
    elem = Event.element(evt);
    setWebOverlapInfo(elem);
}

function setWebOverlapInfo(elem) {
    var opt = elem.id.gsub('document_streaming_for_','').strip();
    if (elem.checked) {
        Irekia.overlapEvents.each(function(oe){
            if (oe.streaming_for.include(opt)) {
                $("overlap_info_"+opt).innerHTML = "AVISO: Coincide con el evento: " + oe.title;
            } else {
                $("overlap_info_"+opt).innerHTML = "";
            }
        });
    } else {
        $("overlap_info_"+opt).innerHTML = "";
    }
}

function setEnDiferidoInfo(elem) {
    var txt = "";
    if (elem.checked) {
        txt = "Cuando hay <b>sólo</b> streaming en <b>diferido</b>, el la web <b>no sale información</b> sobre el streaming."
    }
    $("overlap_info_en_diferido").innerHTML = txt;
    $("overlap_info_en_diferido").addClassName("help_info");
}
