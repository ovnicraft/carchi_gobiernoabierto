$(document).ready(function() {
  // Toggle visibility of home carousel
  $('#toggle_leading').on('click', function() {
    $('#toggle_leading').html($('#toggle_leading').data($('#home_leading_content').css('display')));
    $('#home_leading_content').slideToggle();
    return false;
  });
  
  $('#photo_video_tabs a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
  });

});
