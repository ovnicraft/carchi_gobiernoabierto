$(document).ready(function(){     
  $('.carousel').scrollable({
    wheelSpeed: 1
  });

  $('div.photo_video_viewer ul.nav-tabs li:last a').bind('click', function(){
    if (Irekia.player) {                                                   
      Irekia.player.pause();
    }
  });
  $('div.photo_video_viewer ul.nav-tabs li:first a').bind('click', function(e){
    if (Irekia.player) {                                                  
      Irekia.player.unload();           
      $('a.player').bind('click', videoPlayList.firstPlay);
    }
  })  

  $('#photo_viewer .carousel.viewer img').on('click', function(e){  
    e.preventDefault();
    if ($(this).hasClass("active")) { return; }
    $a = $(this).parent('a');
    $wrap = $(this).parents('.viewer_carousel').siblings('.image_wrap').find("img");                      
    $wrap.attr('src', $a.attr('href'));

    $wrap.on('load', function(e){
      e.stopImmediatePropagation(); 
      new_class = $a.hasClass('landscape') ? 'landscape' : 'portrait';
      $('#photo_viewer .image_wrap').removeClass('landscape portrait').addClass(new_class);  
      // Change caption
      $container = $('#' + $(this).parents('div.x_viewer').attr('id'));
      $container.find('div[class*=item_]').removeClass("active").addClass("passive"); 
      $container.find('div.' + $a.attr('class').split(' ')[0]).removeClass('passive').addClass('active');  
    })
  });

  if ($('#photo_viewer').length > 0 && !($.fn.lightBox === undefined)){
    $('#photo_viewer .carousel .item_thumb a').lightBox({
      imageCaption: $('div.caption')
    });
  }

  $('#video_viewer .carousel.viewer img').on('click', function(e){  
    e.preventDefault();
    if ($(this).hasClass("active")) { return; }
    $a = $(this).parent('a');
    $(".items a").removeClass("active");          
    $(this).addClass("active");
    // Change caption
    $container = $('#' + $(this).parents('div.x_viewer').attr('id'));
    $container.find('div[class*=item_]').removeClass("active").addClass("passive");
    $container.find('div.' + $a.attr('class').split(' ')[0]).removeClass('passive').addClass('active');
  })

  if ($('#photo_viewer').length > 0 && !($.fn.lightBox === undefined)){
    $('#photo_viewer .carousel .item_thumb a').lightBox({
      imageCaption: $('div.caption')
    });
  }
  
});

function changeCaptions(elem){
  $a = elem.parent('a');
  $container = $('#' + elem.parents('div.x_viewer').attr('id'));
  $container.find('div[class*=item_]').removeClass("active").addClass("passive"); 
  $container.find('div.' + $a.attr('class').split(' ')[0]).removeClass('passive').addClass('active');  
}