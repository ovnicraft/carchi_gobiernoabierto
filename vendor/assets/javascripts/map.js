var map,
    mini_marker;		    // If we need to edit the position of the mini marker

function startMiniMap (mapID, lat, lng, enableZoom) {
  var center = new google.maps.LatLng(lat, lng);
  var defaultZoom = defaultZoom || 15;
  var latlng = center;
  var myOptions = {
    zoom: defaultZoom,
    zoomControl: enableZoom,
    center: latlng,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    navigationControl: false,
    disableDefaultUI: false,
    streetViewControl: false,
    mapTypeControl: false,
    navigationControlOptions: {
      style: google.maps.NavigationControlStyle.SMALL
    },
    maxZoom: 16
  };

  map = new google.maps.Map(document.getElementById(mapID), myOptions);

  var center = new google.maps.LatLng(lat, lng);

  var image = new google.maps.MarkerImage('/assets/icons/maps_marker.png');

  mini_marker = new google.maps.Marker({ position: center, map: map, icon: image });
  var mapBounds = new google.maps.LatLngBounds();
  mapBounds.extend(center);
  map.fitBounds(mapBounds);
}
