RHMapbox = {};

(function() {
  RHMapbox.map;
  RHMapbox.overlays;
  RHMapbox.geolocationLayer;
  RHMapbox.htmlID;

  RHMapbox.updateOverviewMap = function(in_data, buildContentStringFn) {
    var info = document.getElementById('info');

    RHMapbox.overlays.clearLayers();
    var markers = new L.MarkerClusterGroup({
      maxClusterRadius: 20 // lean towards showing more individual markers
    }).addTo(RHMapbox.overlays);

    var dataPoints;
    // if updating from an ajax call, in_data will hava content.
    // we load data from a data attribute on page load, but that remains cached forever -
    // it will not update with subsequent ajax calls.
    if (in_data) {
      dataPoints = JSON.parse(in_data);
    } else {
      dataPoints = JSON.parse($('#' + RHMapbox.htmlID).attr('data-map-points'));
    }

    Object.keys(dataPoints).forEach(function(key, index) {
      // draw each marker + load with data
      var info = dataPoints[key];
      var content = buildContentStringFn(key, info);
      //Start marker for rooms dept change when working on listing checkbox checked with sky blue color
      if (window.location.pathname == '/residential_listings/room_index'){
        if (info['working_this_listing'] == true){
          var marker = L.marker(new L.LatLng(info.lat, info.lng), {
            icon: L.mapbox.marker.icon({
              'marker-color': '#00ccff'
            }),
            'title': key,
          });
        }
        else{
          var marker = L.marker(new L.LatLng(info.lat, info.lng), {
            icon: L.mapbox.marker.icon({
              'marker-color': '#f86767'
            }),
            'title': key,
          });
        }
      }
      //End marker for rooms dept change when working on listing checkbox checked with sky blue color
      // Start normal rental page marker mapper with red color
      else{
        var marker = L.marker(new L.LatLng(info.lat, info.lng), {
          icon: L.mapbox.marker.icon({
            'marker-color': '#f86767'
          }),
          'title': key,
        });
      }
      // End normal rental page marker mapper with red color
      // console.log('JUST BEFORE', content);
      marker.bindPopup(content, {
        closeButton: false,
        // minWidth: 100
      });
      markers.addLayer(marker);
    });

    if (Object.keys(dataPoints).length) {
      RHMapbox.map.addLayer(markers);
      // RHMapbox.map.fitBounds(markers.getBounds());
    }
  };

  // htmlID looks something like 'r-big-map'
  // so then jqueryElem will look like $('#r-big-map')
  RHMapbox.initMapbox = function (htmlID, buildContentStringFn) {
    if ($('#' + htmlID).length > 0) {
      RHMapbox.htmlID = htmlID;

      if (RHMapbox.map) {
        RHMapbox.map.remove();
      }

      L.mapbox.accessToken = $('#mapbox-token').attr('data-mapbox-token');
      RHMapbox.map = L.mapbox.map(RHMapbox.htmlID, null, {
          zoomControl: false,
          dragging: true,
          touchZoom: true,
          doubleClickZoom: true,
          scrollWheelZoom: true,
          tap: true
        }).setView([40.6739591, -73.9570342], 13).addLayer(L.mapbox.styleLayer('mapbox://styles/rakelblujeans/ckg0assyj20uq19qvut6w9vu9'));
 
      // RHMapbox.map = L.mapbox.map(RHMapbox.htmlID).addLayer(L.mapbox.styleLayer('mapbox://styles/rakelblujeans/ckg0assyj20uq19qvut6w9vu9'));
        // .setView([40.6739591, -73.9570342], 13);
      RHMapbox.overlays = L.layerGroup().addTo(RHMapbox.map);
      RHMapbox.updateOverviewMap(null, buildContentStringFn);

      // This uses the HTML5 geolocation API, which is available on
      // most mobile browsers and modern browsers, but not in Internet Explorer
      //
      // See this chart of compatibility for details:
      // http://caniuse.com/#feat=geolocation
      RHMapbox.geolocationLayer = L.mapbox.featureLayer().addTo(RHMapbox.map);

      // Once we've got a position, zoom and center the map
      // on it, and add a single marker.
      RHMapbox.map.on('locationfound', function(e) {
        RHMapbox.geolocationLayer.setGeoJSON({
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [e.latlng.lng, e.latlng.lat]
          },
          properties: {
            'title': 'Your current location',
            'marker-color': '#FFA500',
            'marker-symbol': 'star'
          }
        });
        // RHMapbox.map.panTo(e.latlng);
      });
      // NOTE: If the user chooses not to allow their location
      // to be shared, do not display any pin.

      // when a marker is open and prev/next are clicked, cycle throw slidehow of images
      $('#' + htmlID).on('click', '.popup .cycle a', function() {
        var $slideshow = $('.slideshow'),
            $newSlide,
            $content = $('.content'),
            $newContentRow;

        if ($(this).hasClass('prev')) {
            $newSlide = $slideshow.find('.active').prev();
            if ($newSlide.index() < 0) {
              $newSlide = $('.image').last();
            }
            $newContentRow = $content.find('.active').prev();
            if ($newContentRow.index() < 0) {
              $newContentRow = $('.contentRow').last();
            }
        } else {
            $newSlide = $slideshow.find('.active').next();
            if ($newSlide.index() < 0) {
              $newSlide = $('.image').first();
            }
            $newContentRow = $content.find('.active').next();
            if ($newContentRow.index() < 0) {
              $newContentRow = $('.contentRow').first();
            }
        }

        $slideshow.find('.active').removeClass('active').hide();
        $newSlide.addClass('active').show();
        $content.find('.active').removeClass('active');
        $newContentRow.addClass('active').show();

        return false;
      });

    }
  }

  RHMapbox.centerOnMe = function() {
    RHMapbox.map.locate({setView: true, maxZoom: 15});
  }
})();
