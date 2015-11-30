//
// GA customized tracking
//

var irekiaTracker = {
  trackDownload: function() {
    var elem = $(this);
    var linkedFileName = elem.attr("href");
    var linkedFileType = linkedFileName.split('.').pop().toUpperCase();

    _gaq.push(['_trackEvent', 'Descarga', linkedFileType, linkedFileName]);
    _gaq.push(['_trackPageview', '/descarga/']);
  },
  
  prepareRelatedContentForTracking: function() {
    var titles = $("div.article h1.title");
    var doc_title = (titles.length > 0) ? $.trim(titles.first().text()) : document.title;

    // Related documents
    $("ul.related div.title a").each(function(index){
      var link = $(this);
      
      // NOTE: txt.trim() does not work in ie8 therefore jQuery $.trim() must be used.
      var related_doc_title = $.trim(link.text()); 

      link.click(function(){
        _gaq.push(['_trackEvent', 'Contenidos Relacionados', doc_title, related_doc_title]);
      });
    });   
  },
  
  enable: function(){
    var tracker = this;
    // Downloads
    $("a").each(function(index){
      var anchor = $(this);
      if (anchor.attr("href") && (anchor.attr("href").match('.pdf') || anchor.hasClass('download'))) {
        anchor.click(tracker.trackDownload);
      }
    });

    // Related
    this.prepareRelatedContentForTracking();    
  }
}

$(document).ready(function(){
  irekiaTracker.enable();  
});
