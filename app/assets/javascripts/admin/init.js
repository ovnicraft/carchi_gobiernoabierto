// Application-specific JavaScript functions.

// Define count method fpr string class.
String.prototype.count=function(s1) {   
    return (this.length - this.replace(new RegExp(s1,"g"), '').length) / s1.length;  
}

// Scope for Irekia specific js variables.
var Irekia = {};

// GA tracking
function trackLink(evt) {
  var elem = evt.element();
  _gaq.push(['_trackEvent', 'Enlace de salida', elem.innerHTML, elem.href])
}

function externalLinks() {
    if (!document.getElementsByTagName) {
      return;
    } else {
      var anchors = document.getElementsByTagName("a");
      for (var i=0; i<anchors.length; i++) {
          var anchor = anchors[i];
          if (anchor.getAttribute("href") && anchor.getAttribute("rel") && anchor.getAttribute("rel").match("external")) {
            anchor.target = "_blank";
            Event.observe(anchor, 'click', trackLink);
          }
      }      
    }
}
Event.observe(window, 'load', externalLinks);

/* Events calendar */

function showDayInfo(day, elem) {
    var clicked_elem = $("d"+day);
    $("event_info").innerHTML = $("event"+day).innerHTML;
    Element.clonePosition($("event_info_window"), elem, {"setWidth": false, "setHeight": false, "offsetLeft": 5, "offsetTop": 5});
    $("event_info_window").show();
}

/* Events form */
function setElementClassIfChecked(checkBox, element) {
    if (checkBox.checked) {
        element.removeClassName('disabled');
        element.childElements().each(function(n) { 
            if ((n.type == 'checkbox') || (n.type == 'radio')) {
                n.enable();
            }
        });
    } else {
        element.addClassName('disabled');
        element.childElements().each(function(n) { 
            if ((n.type == 'checkbox') || (n.type == 'radio')) {
                n.checked = false;
                n.disable();
            }
        });
    }
}

function showEmbedCode(container, textarea) {
    $(container).toggle();
    $(textarea).focus();
    $(textarea).select();
}

function showEmbedCode2(embed_link) {
  var embed_container = embed_link.up().next('div.embed_container');
  embed_container.toggle();
  embed_container.down('textarea').focus();
  embed_container.down('textarea').select();
}

function showTags(tags_link, show_text, hide_text) {
  var tags_container = tags_link.up().next('div.tags');
  tags_container.toggle();
  if (tags_container.style.display == 'none') {
    tags_link.down('span.m').innerHTML = show_text;
  } else {
    tags_link.down('span.m').innerHTML = hide_text;
  }
}


function confirmAndDisable(elem, perform_confirmation, confirm_msg, disable_msg) {
    result = perform_confirmation ? confirm(confirm_msg) : true
    if (result) {
        if (window.hiddenCommit) { 
            window.hiddenCommit.setAttribute('value', this.value); 
        } else { 
            hiddenCommit = elem.cloneNode(false);
            hiddenCommit.setAttribute('type', 'hidden');
            elem.form.appendChild(hiddenCommit); 
        }
        elem.setAttribute('originalValue', this.value);
        elem.disabled = true;
        elem.value = disable_msg;
        result = (elem.form.onsubmit ? (elem.form.onsubmit() ? elem.form.submit() : false) : elem.form.submit());
        if (result == false) { 
            elem.value = this.getAttribute('originalValue');
            elem.disabled = false; 
        }
    }
    return result;
}

// News and proposals
function togglePublicationDateVisibility(item, guardar, publicar) {
    if ($(item + '_draft').checked) {
        $('publication_date').style.display = 'none';
        $$('input.submit_button').each(function(s) {
            s.value = guardar;
        });
    } else {
        $('publication_date').style.display = 'block';
        $$('input.submit_button').each(function(s) {
            s.value = publicar;
        });
    }
}

function PastOrFuture(item, programar, publicar) {
    var form_date = new Date($(item+'_published_at_1i').value,  $(item+'_published_at_2i').value -1,  $(item+'_published_at_3i').value, $(item+'_published_at_4i').value, $(item+'_published_at_5i').value, 00);

    var now = new Date();

    if (form_date > now) {
        $$('input.submit_button').each(function(s) {
            s.value = programar;
        });
    } else {
        $$('input.submit_button').each(function(s) {
            s.value = publicar;
        });
    }
}

function toggleBodyContainer(toggler, containerId, showText, hideText) {
  $(containerId).toggle();
  if ($(containerId).style.display == 'none') {
    toggler.innerHTML = showText;
  } else {
    toggler.innerHTML = hideText;
  }
}

// / News and proposals

// Debates
function toggleStageActive(elem) {
  var destroyInput = $(elem.id.replace("active", "_destroy"));

  if (elem.checked) {
    $(elem).up("tr").removeClassName("disabled")
    destroyInput.value = 0;
  } else {
    $(elem).up("tr").addClassName("disabled")    
    destroyInput.value = 1;    
  }
}
// /Debates

// toreview: delete this
// Ajax pagination
// document.observe("dom:loaded", function() {
//   // the element in which we will observe all clicks and capture
//   // ones originating from pagination links
//   var container = $(document.body)

//   if (container) {
//     var img = new Image
//     img.src = '/images/admin/spinner.gif'

//     function createSpinner() {
//       return new Element('img', { src: img.src, 'class': 'spinner' })
//     }

//     container.observe('click', function(e) {
//       var el = e.element()
//       if (el.match('.pagination.ajax a')) {
//         el.up('.pagination').insert(createSpinner())
//         new Ajax.Request(el.href, { method: 'get' })
//         e.stop()
//       }
//     })
//   }
// })

/* WebTV y fototeca */
function toggleContentBlock(evt) {
  var elem = Event.element(evt);
  var parent_elem = elem.up('div.toggable');

  if (parent_elem.hasClassName('toggable')) {
    parent_elem = parent_elem.up('div');
  }
  var content_elem;
  
  if (parent_elem) {    
    parent_elem.toggleClassName("cerrado");
    parent_elem.toggleClassName("abierto");    
    
    if (parent_elem.id === 'related_articles_block') {
      content_elem = parent_elem.down('ul.documents');
    } else {
      content_elem = parent_elem.down('div.content_block');
    }
    
    if (content_elem) {
      if (parent_elem.hasClassName('cerrado')) {
        //new Effect.SlideUp(content_elem.id, { duration: 3.0 }); NO funciona
        content_elem.fade();
      }
      if (parent_elem.hasClassName('abierto')) {
        //new Effect.SlideDown(content_elem.id); No funciona
        content_elem.appear();
      }
    }
    
  }   
}
function initOpenCloseLinks(evt) {
  $$('div.one_channel').each(function(block) {
    if (block.hasClassName('abierto') || block.hasClassName('cerrado'))
      var elem = block.down('div.channel_title')
      elem.addClassName('toggable');
      Event.observe(elem, 'click', toggleContentBlock) 
  });  
}

Event.observe(window, 'load', initOpenCloseLinks);



function remove_fields(link) {
  $(link).previous("input[type=hidden]").value = "1";
  $(link).up(".attachment").hide();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  $(link).up().insert({
    before: content.replace(regexp, new_id)
  });
}

Event.observe(window, 'load', function () {
  $$('.help_link').each(function(element) {
    element.observe('click', toggleHelp);
  });
});

function toggleHelp (e) {
  this.up('div').select('div.help').first().toggle();
  e.stop();
}