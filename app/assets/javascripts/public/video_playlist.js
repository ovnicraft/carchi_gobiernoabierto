var videoPlayList = {
  
  init: function() {
    if ($('a.player').length > 0) {
      if (Irekia.player) {                         
        // If use flowplayer.playlist
        Irekia.player.playlist("div#clips", {loop:true});  
        $('a.player').on('click', this.firstPlay);

        Irekia.player.onStart(function(clip) {                                

        	var captionUrl = $("a.item_"+String(clip.index)).data("captions");
        	clip.captionUrl = captionUrl;

          var captions = Irekia.player.getPlugin("captions");
          if (captionUrl.length > 0) {
           captions.loadCaptions(clip.index, clip.captionUrl);
           Irekia.player.getPlugin("content").show();
          } else {
            Irekia.player.getPlugin("content").setHtml("Los subtítulos no están disponibles.");                    
            Irekia.player.getPlugin("content").hide();          
          }
        });
      }
    } else {                     
      // html5 video element
      if ($('video').first()) {
        var video = $('video').first();      
        $('#clips').find("a").each(function(index){ 
          elem = $(this);
          elem.bind('click', function(event) {
            event.preventDefault();                 
            var el = $(this);
            var track = null; 
            video.trigger('pause');

            video.attr('src', el.data("m4vsrc"));
            video.attr('title', el.find('span.video_title').first().html());
            video.attr('poster', el.find('img').attr('src'));
            
            track = video.find('track');
            if ((track !== "undefined") && (track !== null)) {
              if (el.data("captions").length > 0) {
                track.attr('src', Irekia.hostWithPort + el.data("captions"));              
              } else {
                track.attr('src', null)
              }
            }
            
            video.trigger('load');
            video.videoSub();            
            video.trigger('play');
          });
        });
      }
    }
  }, 
  
  firstPlay: function(e){
    e.preventDefault();
    $('div#clips div.item_thumb:first a').click();    
    $(this).unbind('click');
  }
  
}

$(document).ready(function(){     
  videoPlayList.init();
});
