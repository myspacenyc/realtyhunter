Buildings = {};

(function () {
  Buildings.timer;

  Buildings.showSpinner = function () {
    $('.index-spinner-desktop').show();
  };

  Buildings.hideSpinner = function () {
    $('.index-spinner-desktop').hide();
  };

  Buildings.filterListings = function (event) {
    var search_path = $('#listings').attr('data-search-path');
    $.ajax({
      url: search_path,
      data: {
        status_listings: $('#status_listings').val(),
      },
      dataType: "script",
      success: function () {
      },
      error: function () {
      }
    });
  };

  Buildings.filterBuildings = function (sortByCol, sortDirection) {
    Buildings.showSpinner();

    var search_path = $('#search-filters').attr('data-search-path');

    if (!sortByCol) {
      sortByCol = Common.getSearchParam('sort_by');
    }
    if (!sortDirection) {
      sortDirection = Common.getSearchParam('direction');
    }

    var data = {
      filter: $('#filter').val(),
      filter_dotsignal_code: $('#filter_dotsignal_code').val(),
      status: $('#status').val(),
      rating: $('#rating').val(),
      streeteasy_eligibility: $('#streeteasy_eligibility').val(),
      train_line: $('#train_line').val(),
      sort_by: sortByCol,
      direction: sortDirection,
    };
    var searchParams = [];
    for(var key in data) {
      if (data.hasOwnProperty(key) && data[key]) {
        searchParams.push(key + "=" + data[key]);
      }
    }
    window.location.search = searchParams.join('&');
  };

  Buildings.sortOnColumnClick = function () {
    $('#buildings .th-sortable').click(function (e) {
      Common.sortOnColumnClick($(this), Buildings.filterBuildings);
    });
  };

  // search as user types
  Buildings.throttledBldgSearch = function () {
    clearTimeout(Buildings.timer);  //clear any interval on key up
    Buildings.timer = setTimeout(Buildings.filterBuildings, 500);
  };

  // change enter key to tab
  Buildings.preventEnter = function (event) {
    if (event.keyCode == 13) {
      $('#buildings #checkbox_active').focus();
      return false;
    }
  };

  Buildings.removeBldgImage = function (id, building_id) {
    // make a DELETE ajax request to delete the file
    $.ajax({
      type: 'DELETE',
      url: '/buildings/' + building_id + '/images/' + id,
      success: function(data){
        //console.log(data.message);
        $.getScript('/buildings/' + building_id + '/refresh_images')
      },
      error: function(data) {
        //console.log('ERROR:', data);
      }
    });
  };

  Buildings.updateRemoveImgLinks = function () {
    $('#buildings .delete-bldg-img').click(function (event) {
      event.preventDefault();
      var id = $(this).attr('data-id');
      var bldg_id = $(this).attr('data-bldg-id');
      // console.log(id, bldg_id);
      Buildings.removeBldgImage(id, bldg_id);
    });
  };

  Buildings.initEditor = function () {
    // disable auto discover
    Dropzone.autoDiscover = false;

    // grap our upload form by its id
    $("#building-dropzone").dropzone({
      // restrict image size to a maximum 1MB
      //maxFilesize: 4,
      //paramName: "upload[image]",
      // show remove links on each image upload
      addRemoveLinks: true,
      // if the upload was successful
      success: function(file, response){
        // find the remove button link of the uploaded file and give it an id
        // based of the fileID response from the server
        $(file.previewTemplate).find('.dz-remove').attr('id', response.fileID);
        $(file.previewTemplate).find('.dz-remove').attr('bldg_id', response.bldgID);
        // add the dz-success class (the green tick sign)
        $(file.previewElement).addClass("dz-success");
        $.getScript('/buildings/' + response.bldgID + '/refresh_images')
        file.previewElement.remove();
      },
      //when the remove button is clicked
      removedfile: function (file) {
        // grap the id of the uploaded file we set earlier
        var id = $(file.previewTemplate).find('.dz-remove').attr('id');
        var bldg_id = $(file.previewTemplate).find('.dz-remove').attr('bldg_id');
        Buildings.removeBldgImage(id, bldg_id);
        file.previewElement.remove();
      }
    });

    Buildings.updateRemoveImgLinks();

    DropZoneHelper.setPositions('buildings', 'images');
    DropZoneHelper.makeSortable('buildings', 'images');

    // after the order changes
    $('#buildings .sortable').sortable().bind('sortupdate', function(e, ui) {
      // array to store new order
      updated_order = []
      // set the updated positions
      DropZoneHelper.setPositions('buildings', 'images');

      // populate the updated_order array with the new task positions
      $('#buildings .img').each(function(i){
        updated_order.push({ id: $(this).data('id'), position: i+1 });
      });
      //console.log(updated_order);

      // send the updated order via ajax
      var bldg_id = $('#buildings').attr('data-bldg-id');
      $.ajax({
        type: "PUT",
        url: '/buildings/' + bldg_id + '/images/sort',
        data: { order: updated_order }
      });
    });

    var bldg_address = $('#map-canvas').attr('data-address') ? $('#map-canvas').attr('data-address') : 'New York, NY, USA';
    // google maps
    $("#bldg_panel").geocomplete({
      map: "#map-canvas",
      location: bldg_address,
      details: ".details"
    }).bind("geocode:result", function (result) {
      // console.log("*****", result);
    }).bind("geocode:error", function (result) {
      // console.log("[ERROR]: " + result);
    });

    $(".autocomplete-input").geocomplete({
      map: "#map-canvas",
      location: bldg_address,
      details: ".details"
    }).bind("geocode:result", function(event, result) {
      if (this.value == "New York, NY, USA") {
        this.value = '';
      }
      // console.log("******". result);

      // update neighborhood options from google results
      var sublocality = '';
      for (var i =0; i<result.address_components.length; i++) {
        if (result.address_components[i].types[1] === "sublocality") {
          sublocality = result.address_components[i].short_name;
        }
      }

      // if no neighborhood already set, update neighborhood from google results
      if ($('#neighborhood').val() === null) {
        $.ajax({
          type: "GET",
          url: '/buildings/neighborhood_options',
          data: {
            sublocality: sublocality,
          },
          success: function (data) {
            for (var i =0; i<result.address_components.length; i++) {
              if (result.address_components[i].types[0] === "neighborhood") {
                var nabe = result.address_components[i].short_name;
                //console.log(nabe);
                $('#neighborhood').val(nabe);
              }
            }
          }
        });
      }

    }).bind("geocode:error", function () {
      console.log("[ERROR]: " + result);
    });
  }

  Buildings.initIndex = function () {
    Buildings.hideSpinner();
    $('#buildings a').click(function () {
      if ($(this).text().toLowerCase().indexOf('csv') === -1) {
        Buildings.showSpinner();
      }
    });

    // main index table
    Buildings.sortOnColumnClick();
    Common.markSortingColumn();
    if (Common.getSearchParam('sort_by') === '') {
      Common.markSortingColumnByElem($('th[data-sort="buildings.formatted_street_address"]'), 'desc')
    }

    // search filters
    $('input').keydown(Buildings.preventEnter);
    $('#filter').bind('railsAutocomplete.select', Buildings.throttledBldgSearch);
    $('#filter').change(Buildings.throttledBldgSearch);
    $('#rating').change(Buildings.throttledBldgSearch);
    $('#streeteasy_eligibility').change(Buildings.throttledBldgSearch);
    $('#filter_dotsignal_code').change(Buildings.throttledBldgSearch);
    $('#train_line').change(Buildings.throttledBldgSearch);
    $('#status').change(Buildings.throttledBldgSearch);
  }

  Buildings.initShow = function () {
    $('.carousel-indicators > li:first-child').addClass('active');
    $('.carousel-inner > .item:first-child').addClass('active');
    $('#status_listings').change(Buildings.filterListings);
  }

  Buildings.ready = function () {
    var editPage = $('.buildings.edit').length;
    var newPage = $('.buildings.new').length;
    var indexPage = $('.buildings.index').length;
    var showPage = $('.buildings.show').length;
    // new and edit pages both render the same form template, so init them using the same code
    if (editPage || newPage) {
      Buildings.initEditor();
    } else if (indexPage) {
      Buildings.initIndex();
    } else if (showPage) {
      Buildings.initShow();
    }
  };
})();

$(document).on('keyup',function (evt) {
  if (evt.keyCode == 27) {
    Buildings.hideSpinner();
  }
});

document.addEventListener('turbolinks:load', Buildings.ready);
