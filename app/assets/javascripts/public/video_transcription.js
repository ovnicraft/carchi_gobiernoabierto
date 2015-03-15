//
// Video transcription tools.
// Requires jQuery.
//
// eli@efaber.net, 11/09/2012

// After the player is loaded, initialize transcription if there is transcription text.
$(function() {
  if ($('div.video_transcription_cuepoint')) {
    if (typeof(initTranscriptionCuepoints) != 'undefined') {
      initTranscriptionCuepoints(Irekia.player);
    }
  }        
});

function initTranscriptionCuepoints(player) {
  var cp = [];

  // Get the cuepoints and bind the click event
  $('div.video_transcription_cuepoint').each(function(index){
    var elem = this;
    var currentTime = parseInt(elem.id.replace('text',''));
    cp.push(currentTime*1000);
    $(elem).click(function(){
      videoTranscript.highlightCuepointText(currentTime);      
      if (!player.isLoaded()) {
        player.load();
      }
      if (!player.isPlaying()) {
        player.play();
      }
      player.seek(currentTime).resume();
    });
  });
  
  // On cuepoint highlight the text
  player.getCommonClip().onCuepoint(cp, function(clip, cuepoint) {
    videoTranscript.highlightCuepointText(cuepoint/1000);
  });
  // On finish, clear current cuepoint
  player.getCommonClip().onFinish(function(){
    videoTranscript.clearCuepointsStyle();
    true;
  });
}


var videoTranscript = {
  current: "",
  container: "",

  getCurrentCuepoint: function() {
    videoTranscript.current = $("div.current_cuepoint").first();
  },

  setCurrentCuepoint: function(cuepoint) {
    $("div.current_cuepoint").removeClass('current_cuepoint');
    videoTranscript.current = $("#text"+cuepoint);
    videoTranscript.current.addClass("current_cuepoint");

    videoTranscript.container = videoTranscript.current.parents('.transcription');
  },

  highlightCuepointText: function(cuepoint) {
    videoTranscript.setCurrentCuepoint(cuepoint);
    if (videoTranscript.bottomReached()) {
      // console.log("bottom reached");
      videoTranscript.smoothScroll();
    }
  },  

  clearCuepointsStyle: function() {
    $("div.current_cuepoint").removeClass('current_cuepoint');
  },

  bottomReached: function() {
    // Cuepoint position inside the visible area.
    // If the position is below the height of the visible area, the bottom is reached.
    var current_top = videoTranscript.current.offset().top - videoTranscript.container.offset().top;

    return current_top > (videoTranscript.container.height() - 40);
  },

  smoothScroll: function() {
    var current_top = videoTranscript.current.offset().top - videoTranscript.container.offset().top;
    
    var new_position = videoTranscript.container.scrollTop() + current_top;
    // console.log("scroll to: "+new_position);
    // videoTranscript.container.scrollTop(new_position);
    
    videoTranscript.container.animate({scrollTop: new_position}, 500);    
  }

}



