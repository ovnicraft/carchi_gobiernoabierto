/*
  qTip enhanced.
*/

ToolTip = Class.create(Abstract, {
	initialize: function (tiptag, options) {
	  var tooltip = this;
	  var qTipTag  = tiptag;
	  tooltip.name = "qTip";
    tooltip.tip = null;
    tooltip.fitsInWindow = true;
    
	  
    tooltip.options    = Object.extend({
      offsetX: 0, //This is qTip's X offset//
      offsetY: 5, //This is qTip's Y offset//
      tipContainerID: "qTip" // The div where the tip is shown//
    }, options || {});
    
    tooltip.offsetX = tooltip.options.offsetX;
    tooltip.offsetY = tooltip.options.offsetY;
    
    var tipNameSpaceURI = "http://www.w3.org/1999/xhtml";
    
    if (!document.getElementById) return;
    
    tooltip.tip = document.getElementById(tooltip.name);
    
    var a, sTitle, elements;
    var elementList = qTipTag.split(",");

    for(var j = 0; j < elementList.length; j++) {	
        elements = $$(elementList[j]);
        if(elements)
        {
            for (var i = 0; i < elements.length; i ++)
            {
                a = elements[i];
                link = a.getAttribute("href");				
                if (link)
                {
                    a.removeAttribute("title");
                    a.removeAttribute("alt");
                    a.onmouseover = function(evt) {tooltip.moveAndShow(this, evt)};
                    a.onmouseout = function() {tooltip.hide()};
                }
            }
        }
    }   
  },
  
  moveAndShow: function(elem, evt) {
    var that = this;
        
    var link_div = elem.up("div.image");
    if (link_div)
      that.move(link_div, evt); 
    
    var tipTextElement = link_div.adjacent("div.image_tip").first();

    if (tipTextElement && that.fitsInWindow)
      that.show(tipTextElement.innerHTML);

  },
  
  move: function (elem, evt) {
    var that = this;
    
    var x=0, y=0;
    var ww = document.viewport.getDimensions(); // el tamaño actual de la ventana del browser
    var tw = Element.getDimensions(that.tip); // el tamaño del tip
            
    var left_scroll = 0;
    var wrapper = elem.up("div.carousel-wrapper");
    var wrapper_right = ww.width;
    
    if (wrapper) {
      left_scroll = wrapper.scrollLeft;
      ww = wrapper.getDimensions();
      wrapper_right = wrapper.positionedOffset().left + left_scroll + ww.width;
    }    
       
    var position_left = elem.cumulativeOffset()[0] - left_scroll;
    //elem.positionedOffset()[0]-left_scroll; // la posición actual del elem en la ventana del browser
    
    var ew = elem.getDimensions(); // el tamaño del elem sobre el que se muestra el tip
    var elem_right = elem.cumulativeOffset().left + ew.width;
    that.fitsInWindow = (elem_right - ew.width/2) < wrapper_right; // si entra más de la mitad, sale el bocadillo
        
    if (that.fitsInWindow) {
      var offsetX = 0; // offset a partir de la posición del elem      
      var offsetY = ew.height - 10;
      
      if ((position_left + tw.width) > ww.width) {
        offsetX = ew.width - tw.width;          
        if (wrapper_right < elem_right) {
          offsetX = offsetX - (elem_right - wrapper_right);
        }
        that.tip.className = 'arrow_right';
      } else {
        that.tip.className = 'arrow_left';
      }

      // ie6 y 7 
      var l;
      // if(Prototype.Browser.IE){ 
      //   l = (elem.positionedOffset())[0]; 
      // } else if(Prototype.Browser.Opera){ 
      //   l = (elem.viewportOffset())[0]-(elem.cumulativeScrollOffset())[0]; 
      // } else { 
      //   l = (elem.viewportOffset())[0]; 
      // }
      
      if ((elem.getOffsetParent().tagName.toUpperCase() ==='HTML') && (elem.getStyle('float') === "left")) {
        // Aquí el offset es absoluto y depende del value para float.
        l = (elem.positionedOffset())[0]; 
        offsetX = offsetX + l - elem.viewportOffset()[0];
      }
      // fin ie6 y 7
      
      
            
      Element.clonePosition(that.tip, elem, {setWidth:false, setHeight:false, offsetLeft:offsetX, offsetTop:offsetY});
    }
  },
  
  show: function (text) {
    var that = this;
    
    if (!that.tip) return;
    
    that.tip.innerHTML = text;
    that.tip.style.display = "block";
   },
   
   hide: function () {
    var that = this;
    
    if (!that.tip) return;
    
    that.tip.innerHTML = "";
    that.tip.style.display = "none";
   }
});

