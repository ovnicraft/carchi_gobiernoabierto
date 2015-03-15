/*
// Función que incluye el iframe con los comentarios en una página.
//
// Las variables globales irekiaClientID, irekiaHost, euskadinetNewsID y widgetLocale 
// tienen que estar definidas antes de llamar a esta función.
*/
(function(window, document, undefined) {
  var commentableTitle = document.title,
      commentableURL = window.location.href,
      localePattern = /\/(e[s|u|n])\//;
  
  var hostName,
      hostProtocol,
      contentLocale,
      embedUrl,
      clientCode,      
      newsID,
      src = null;
  
  hostProtocol = window.location.protocol;
  
  if (typeof(irekiaHost) != "undefined"){
    hostName = irekiaHost;
  } else {
    hostName = "irekia.euskadi.net"
  }
  
  contentLocale = "es";
  if (typeof(widgetLocale) != "undefined") {
    if ( (widgetLocale === "eu") || (widgetLocale === "en")) {
      contentLocale = widgetLocale;
    }
  } else {
    if ((matchArray = localePattern.exec(commentableURL)) != null) {
      contentLocale = matchArray[1];
    }
  }  

    
  embedUrl = hostProtocol+"//"+hostName+"/"+contentLocale+"/embed/comment?";
  
  if (typeof(irekiaClientCode) != "undefined") {    
    clientCode = irekiaClientCode;    
    src = embedUrl+"client="+clientCode+"&url="+commentableURL+"&title="+commentableTitle;
  }
  
  if (typeof(irekiaNewsID)  != "undefined") {
    newsID = irekiaNewsID;    
    src = embedUrl+"news_id="+newsID+"&url="+commentableURL+"&title="+commentableTitle;    
  }

  if (typeof(euskadinetNewsID)  != "undefined") {
    newsID = "euskadinetNewsID-"+euskadinetNewsID;    
    src = embedUrl+"content_local_id="+newsID+"&url="+commentableURL+"&title="+commentableTitle;    
  }

  if (src != null) {
    var iframe = document.createElement('iframe');
    iframe.frameBorder=0;
    iframe.width="100%";
    iframe.height="1000px";
    iframe.id="comments_iframe";
    iframe.setAttribute("src", src);
    document.getElementById("irekia_comments").appendChild(iframe); 
  }
   
})(window, document);
