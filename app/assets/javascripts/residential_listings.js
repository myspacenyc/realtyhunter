  ResidentialListings = {};

(function() {
  ResidentialListings.timer;
  ResidentialListings.announcementsTimer;
  ResidentialListings.selectedNeighborhoodIds = null;
  ResidentialListings.selectedUnitAmenityIds = null;
  ResidentialListings.selectedBuildingAmenityIds = null;

  ResidentialListings.wasAlreadyInitialized = function() {
    return !!$('.residential_listings').attr('initialized');
  }

  // for searching on the index page
  ResidentialListings.doSearch = function (sortByCol, sortDirection) {
    Listings.showSpinner();

    var search_path = $('#res-search-filters').attr('data-search-path');

    if (!sortByCol) {
      sortByCol = Common.getSearchParam('sort_by');
    }
    if (!sortDirection) {
      sortDirection = Common.getSearchParam('direction');
    }

    var data = {
        address: $('#address').val(),
        unit: $('#unit').val(),
        rent_min: $('#rent_min').val(),
        rent_max: $('#rent_max').val(),
        bed_min: $('#bed_min').val(),
        bed_max: $('#bed_max').val(),
        bath_min: $('#bath_min').val(),
        bath_max: $('#bath_max').val(),
        landlord: $('#landlord').val(),
        listing_id: $('#listing_id').val(),
        pet_policy_shorthand: $('#pet_policy_shorthand').val(),
        available_starting: $('#available_starting').val(),
        available_before: $('#available_before').val(),
        status: $('#status').val(),
        has_fee: $('#has_fee').val(),
        roomsharing_filter: $('#roomsharing_filter').prop('checked'),
        unassigned_filter: $('#unassigned_filter').prop('checked'),
        tenant_occupied_filter: $('#tenant_occupied_filter').prop('checked'),
        has_stock_photos_filter: $('#has_stock_photos_filter').prop('checked'),
        no_description: $('#no_description').prop('checked'),
        no_images: $('#no_images').prop('checked'),
        streeteasy_filter: $('#streeteasy_filter').val(),
        primary_agent_id:  $('#primary_agent_id').val(),
        sort_by: sortByCol,
        direction: sortDirection
      };

    if (ResidentialListings.selectedNeighborhoodIds && ResidentialListings.selectedNeighborhoodIds.length) {
      data.neighborhood_ids = ResidentialListings.selectedNeighborhoodIds;
    }
    if (ResidentialListings.selectedUnitAmenityIds && ResidentialListings.selectedUnitAmenityIds.length) {
      data.unit_feature_ids = ResidentialListings.selectedUnitAmenityIds;
    }
    if (ResidentialListings.selectedBuildingAmenityIds && ResidentialListings.selectedBuildingAmenityIds.length) {
      data.building_feature_ids = ResidentialListings.selectedBuildingAmenityIds;
    }

    var searchParams = [];
    for (var key in data) {
      if (data.hasOwnProperty(key) && data[key]) {
        searchParams.push(key + "=" + data[key]);
      } else {
        // console.log('OTHER: ', key);
      }
    }

    window.location.search = searchParams.join('&');
  };

  ResidentialListings.clearAnnouncementsTimer = function() {
    if (ResidentialListings.announcementsTimer) {
      clearTimeout(ResidentialListings.announcementsTimer);
    }
  };

  ResidentialListings.clearTimer = function() {
    if (ResidentialListings.timer) {
      clearTimeout(ResidentialListings.timer);
    }
  };

  ResidentialListings.queryAnnouncementsOnMobile = function(limit) {
    $.ajax({
      url: '/residential_listings/update_announcements_mobile',
      data: {
        limit: limit ? limit : 4,
      }
    });
  }

  ResidentialListings.closeCheckInCard = function() {
    $('.checkIn-form').html('');
    $('.checkIn-form').addClass('hidden');
    $('.card.check-in').removeClass('fadeToInvisible');
    $('.checkIn-confirmationMsg').addClass('hidden');
  };

  ResidentialListings.queryCheckinOptions = function() {
    $('.checkIn-spinner').removeClass('hidden');
    $('.checkIn-confirmationMsg').addClass('hidden');

    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(function() {});
      navigator.geolocation.getCurrentPosition(function(position) {
        // console.log('initial', position);
        $.ajax({
          url: '/residential_listings/check_in_options',
          data: {
            current_location: [position.coords.latitude, position.coords.longitude],
            distance: 300 // feet
          }
        });
      }, function() {}, {
        timeout: 30 * 1000,
        maximumAge: Infinity
      });
    }
  }

  // update the announcements every 60 seconds
  ResidentialListings.updateAnnouncements = function() {
    //console.log('updateAnnouncements ', $('.residential').length);
    if ($('.announcement').length) {
      //console.log('updating ann');
      $.ajax({
        url: '/residential_listings/update_announcements',
        data: {
          limit: limit ? limit : 4,
        }
      });

      ResidentialListings.announcementsTimer = setTimeout(ResidentialListings.updateAnnouncements, 60 * 1 * 1000);
    }
  };

  // ResidentialListings.enablePassiveUpdates = function() {
  //   if (!Common.onMobileDevice()) {
  //     ResidentialListings.passiveRealTimeUpdate();
  //     ResidentialListings.updateAnnouncements();
  //   }
  // }

  // if a user remains on this page for an extended amount of time,
  // refresh the page every so often. We want to make sure they are
  // always viewing the latest data.
  // ResidentialListings.passiveRealTimeUpdate = function() {
    // ResidentialListings.clearTimer();
    // update every few minutes
    // ResidentialListings.timer = setTimeout(ResidentialListings.doSearch, 60 * 10 * 1000);
  // };

  // search as user types
  ResidentialListings.throttledSearch = function () {
    //clear any interval on key up
    ResidentialListings.clearTimer();
    ResidentialListings.timer = setTimeout(ResidentialListings.doSearch, 500);
  };

  ResidentialListings.preventEnter = function (event) {
    if (event.keyCode == 13) {
      return false;
    }
  };

  // for giant google map
  ResidentialListings.buildContentString = function (key, info) {
    var slideshowContent = '';
    var contentString = '<strong>' + key + '</strong><br />';

    var firstImageAdded = false;
    var imgCount = 0;
    for (var i=0; i<info['units'].length; i++) {

      unit = info['units'][i];

      if (unit.image) {
        slideshowContent += '<div class="image' + (!firstImageAdded ? ' active' : '') + '">' +
            '<a href="https://myspace-realty-monster.herokuapp.com/residential_listings/'+ unit.id +
            '"><img src="' + unit.image + '" /></a>' +
            '</div>';
        firstImageAdded = true;
        imgCount++;
      }

      var shouldHighlightRow = imgCount == 1 && info['units'].length > 1;
      
      if (unit.public_url != null){
        var set_icon = '<input type = "radio" class = "rd_copy_btn"  id = "copylinkup_'+i+'" name = "copylink" value = '+ i +' data-clipboard-target="#copycontent_'+i+'">'
      }else{
        var set_icon = ''
      }


      contentString += '<div class="contentRow' + (shouldHighlightRow ? ' active' : '') +'">'
        + ''+set_icon+''
        + '<a id = "copycontent_'+i+'" href='+unit.public_url+'></a>'
        + '<a href="https://myspace-realty-monster.herokuapp.com/residential_listings/'
        + unit.id + '">#' + unit.building_unit + ' ' +
        + unit.beds + ' bd / '
        + unit.baths + ' baths $' + unit.rent + '</a></div>';
      if (i == 5) {
        contentString += '<div class="contentRow"><a href="https://myspace-realty-monster.herokuapp.com/buildings/'
          + info['building_id'] + '">View more...</a></div>';
        break;
      }
    }
    // contentString += '<button type="button" class = "finalcopylink" >Copy Link!</button>'
    output =
      '<div class="slideshow">' +
        slideshowContent +
      '</div>';
    if (imgCount > 1) {
      output += '<div class="cycle">' +
        '<a href="#" class="prev">&laquo; Previous</a>' +
        '<a href="#" class="next">Next &raquo;</a>' +
        '</div>';
    }
    output += '<div class="content">' +
      contentString +
      '</div>';
    return '<div class="popup">' + output + '</div>';
  };

  ResidentialListings.toggleFeeOptions = function(event) {
    var isChecked = $('.has-fee').prop('checked');
    if (isChecked) {
      $('.show-op').addClass('hide');
      $('.show-tp').removeClass('hide');
    } else {
      $('.show-op').removeClass('hide');
      $('.show-tp').addClass('hide');
    }
  };

  ResidentialListings.inheritFeeOptions = function() {
    bldg_id = $('#residential_listing_unit_building_id').val();

    $.ajax({
      type: 'GET',
      url: '/residential_listings/fee_options/',
      data: {
        building_id: bldg_id,
      }
    });
  };

  ResidentialListings.sortOnColumnClick = function() {
    $('.th-sortable').click(function(e) {
      Common.sortOnColumnClick($(this), ResidentialListings.doSearch);
    });
  };

  ResidentialListings.initializeImageDropzone = function() {
    // grap our upload form by its id
    $("#runit-dropzone").dropzone({
      // restrict image size to a maximum 1MB
      // show remove links on each image upload
      addRemoveLinks: true,
      // if the upload was successful
      success: function(file, response){
        // find the remove button link of the uploaded file and give it an id
        // based of the fileID response from the server
        $(file.previewTemplate).find('.dz-remove').attr('id', response.fileID);
        $(file.previewTemplate).find('.dz-remove').attr('unit_id', response.unitID);
        // add the dz-success class (the green tick sign)
        $(file.previewElement).addClass("dz-success");
        $.getScript('/residential_listings/' + response.runitID + '/refresh_images')
        file.previewElement.remove();
      },
      //when the remove button is clicked
      removedfile: function(file){
        // grap the id of the uploaded file we set earlier
        var id = $(file.previewTemplate).find('.dz-remove').attr('id');
        var unit_id = $(file.previewTemplate).find('.dz-remove').attr('unit_id');
        DropZoneHelper.removeImage(id, unit_id, 'residential_listings');
        file.previewElement.remove();
      }
    });

    DropZoneHelper.updateRemoveImgLinks('residential', 'residential_listings');

    $('.carousel-indicators > li:first-child').addClass('active');
    $('.carousel-inner > .item:first-child').addClass('active');

    DropZoneHelper.setPositions('residential', 'images');
    DropZoneHelper.makeSortable('residential', 'images');

    // after the order changes
    $('.sortable').sortable().bind('sortupdate', function(e, ui) {
        // array to store new order
        updated_order = []
        // set the updated positions
        DropZoneHelper.setPositions('residential', 'images');

        // populate the updated_order array with the new task positions
        $('.img').each(function(i) {
          updated_order.push({ id: $(this).data('id'), position: i});
        });
        //console.log(updated_order);
        // send the updated order via ajax
        var unit_id = $('#residential').attr('data-unit-id');
        $.ajax({
          type: "PUT",
          url: '/residential_listings/' + unit_id + '/unit_images/sort',
          data: { order: updated_order }
        });
    });
  };

  ResidentialListings.initializeDocumentsDropzone = function() {
    // grap our upload form by its id
    $("#runit-dropzone-docs").dropzone({
      // show remove links on each image upload
      addRemoveLinks: true,
      // if the upload was successful
      success: function(file, response){
        // find the remove button link of the uploaded file and give it an id
        // based of the fileID response from the server
        $(file.previewTemplate).find('.dz-remove').attr('id', response.fileID);
        $(file.previewTemplate).find('.dz-remove').attr('unit_id', response.runitID);
        // add the dz-success class (the green tick sign)
        $(file.previewElement).addClass("dz-success");
        $.getScript('/residential_listings/' + response.runitID + '/refresh_documents')
        file.previewElement.remove();
      },
      //when the remove button is clicked
      removedfile: function(file){
        // grap the id of the uploaded file we set earlier
        var id = $(file.previewTemplate).find('.dz-remove').attr('id');
        var unit_id = $(file.previewTemplate).find('.dz-remove').attr('unit_id');
        DropZoneHelper.removeDocument(id, unit_id, 'residential_listings');
        file.previewElement.remove();
      }
    });

    DropZoneHelper.updateRemoveDocLinks('residential', 'residential_listings');
    DropZoneHelper.setPositions('residential', 'documents');
    DropZoneHelper.makeSortable('residential', 'documents');

    // after the order changes
    $('.documents.sortable').sortable().bind('sortupdate', function(e, ui) {
        // array to store new order
        updated_order = []
        // set the updated positions
        DropZoneHelper.setPositions('residential', 'documents');

        // populate the updated_order array with the new task positions
        $('.doc').each(function(i){
          updated_order.push({ id: $(this).data('id'), position: i });
        });
        // send the updated order via ajax
        var unit_id = $('#residential').attr('data-unit-id');
        $.ajax({
          type: "PUT",
          url: '/residential_listings/' + unit_id + '/documents/sort',
          data: { order: updated_order }
        });
    });
  };

  ResidentialListings.commissionAmount = function() {
    if ($('#residential_listing_cyof_true').is(":checked")) {
      $("#residential_listing_commission_amount").val('0');
      $("#residential_listing_commission_amount").attr("readonly", "readonly");
    }
    $('input[name="residential_listing[cyof]"]').change(function() {
      if ($(this).attr("id")=="residential_listing_cyof_true") {
        $("#residential_listing_commission_amount").val('0');
        $("#residential_listing_commission_amount").attr("readonly", "readonly");
      }
      else
      {
        $("#residential_listing_commission_amount").val('');
        $("#residential_listing_commission_amount").removeAttr("readonly");
      }
    });
  };

  ResidentialListings.rlsnyValidation = function() {
    if ($('#residential_listing_rlsny').is(":checked")) {
      $("#residential_listing_floor").attr("required", true);
      $("#residential_listing_total_room_count").attr("required", true);
      $("#residential_listing_condition").attr("required", true);
      $("#residential_listing_showing_instruction").attr("required", true);
      $("#residential_listing_commission_amount").attr("required", true);

      $('label[for="residential_listing_floor"]').addClass("required");
      $('label[for="residential_listing_total_room_count"]').addClass("required");
      $('label[for="residential_listing_condition"]').addClass("required");
      $('label[for="residential_listing_showing_instruction"]').addClass("required");
      $('label[for="residential_listing_commission_amount"]').addClass("required");
      $('label[for="residential_listing_cyof"]').addClass("required");
      $('label[for="residential_listing_share_with_brokers"]').addClass("required");
    }
    $('input[name="residential_listing[rlsny]"]').change(function() {
      if ($(this).is(":checked")) {
        $("#residential_listing_floor").attr("required", true);
        $("#residential_listing_total_room_count").attr("required", true);
        $("#residential_listing_condition").attr("required", true);
        $("#residential_listing_showing_instruction").attr("required", true);
        $("#residential_listing_commission_amount").attr("required", true);

        $('label[for="residential_listing_floor"]').addClass("required");
        $('label[for="residential_listing_total_room_count"]').addClass("required");
        $('label[for="residential_listing_condition"]').addClass("required");
        $('label[for="residential_listing_showing_instruction"]').addClass("required");
        $('label[for="residential_listing_commission_amount"]').addClass("required");
        $('label[for="residential_listing_cyof"]').addClass("required");
        $('label[for="residential_listing_share_with_brokers"]').addClass("required");
      }
      else
      {
        $("#residential_listing_floor").removeAttr("required");
        $("#residential_listing_total_room_count").removeAttr("required");
        $("#residential_listing_condition").removeAttr("required");
        $("#residential_listing_showing_instruction").removeAttr("required");
        $("#residential_listing_commission_amount").removeAttr("required");

        $('label[for="residential_listing_floor"]').removeClass("required");
        $('label[for="residential_listing_total_room_count"]').removeClass("required");
        $('label[for="residential_listing_condition"]').removeClass("required");
        $('label[for="residential_listing_showing_instruction"]').removeClass("required");
        $('label[for="residential_listing_commission_amount"]').removeClass("required");
        $('label[for="residential_listing_cyof"]').removeClass("required");
        $('label[for="residential_listing_share_with_brokers"]').removeClass("required");
      }
    });
  };

  ResidentialListings.toggleExpirationDateUI = function() {
    if ($('#residential_listing_unit_is_exclusive_agreement_signed')[0].checked) {
      $('.row-is_exclusive_agreement_signed').removeClass('hidden');
    } else {
      $('.row-is_exclusive_agreement_signed').addClass('hidden');
    }
  };

  ResidentialListings.initEditor = function() {
    $('.has-fee').click(ResidentialListings.toggleFeeOptions);
    ResidentialListings.toggleFeeOptions();
    // when creating a new listing, inherit TP/OP from building's landlord
    $('#residential_listing_unit_building_id').change(ResidentialListings.inheritFeeOptions);
    // when toggling whether there's a signed exclusive agreement
    ResidentialListings.toggleExpirationDateUI();
    $('#residential_listing_unit_is_exclusive_agreement_signed').click(
        ResidentialListings.toggleExpirationDateUI);

    // for drag n dropping photos/docs
    // disable auto discover
    Dropzone.autoDiscover = false;
    ResidentialListings.initializeImageDropzone();
    ResidentialListings.initializeDocumentsDropzone();

    ResidentialListings.commissionAmount();
    ResidentialListings.rlsnyValidation();
  }

  ResidentialListings.showCard = function(cardName, e) {
    $('.card.main').removeClass('card-visible');
    $('.card.check-in').removeClass('card-visible');
    $('.card.mobile-filters').removeClass('card-visible');
    $('.card.announcements').removeClass('card-visible');
    $('.card.list-view').removeClass('card-visible');
    $('.card.' + cardName).addClass('card-visible');

    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }
  };

  // called on index & show pages
  ResidentialListings.initMobileIndex = function() {
    navigator.geolocation.getCurrentPosition(function(position) {
    }, function() {}, {
      timeout: 30 * 1000,
      maximumAge: Infinity
    });

    $('#residential-desktop').remove();
    $('#residential-mobile input').keydown(ResidentialListings.preventEnter);

    $('.js-show-mobile-filters').click(function(e) {
      ResidentialListings.showCard('mobile-filters', e);
    });

    $('.js-show-check-in').click(function(e) {
      ResidentialListings.showCard('check-in', e);
      ResidentialListings.queryCheckinOptions();
    });

    $('.js-show-announcements').click(function() {
      ResidentialListings.showCard('announcements');
      ResidentialListings.queryAnnouncementsOnMobile(100);
    });

    $('.js-show-map').click(function(e) {
      ResidentialListings.showCard('main', e);
      RHMapbox.centerOnMe();
    });

    $('.js-show-list-view').click(function(e) {
      ResidentialListings.showCard('list-view', e);
    });

    $('.js-run-search').click(function(e) {
      ResidentialListings.showCard('main', e);
      ResidentialListings.throttledSearch();
    });

    $('.js-show-main').click(function(e) {
      ResidentialListings.showCard('main', e);
    });

    $('.js-cancel-search').click(function(e) {
      ResidentialListings.showCard('main', e);
    });

    $('.js-reset-filters').click(function(e) {
      $('#address').val('');
      $('#rent_min').val('');
      $('#rent_max').val('');
      $('#bed_min').val('Any');
      $('#bed_max').val('Any');
      $('#bath_min').val('Any');
      $('#bath_max').val('Any');
      $('#status').val('Active');
      $('#pet_policy_shorthand').val('Any');
      $('#neighborhood-select-multiple')[0].selectize.clear();
      $('#unit-amenities-select-multiple')[0].selectize.clear();
      $('#building-amenities-select-multiple')[0].selectize.clear();
    })

    // only on index, not show page
    if ($('#r-big-map-mobile').length) {
      RHMapbox.initMapbox('r-big-map-mobile', ResidentialListings.buildContentString);
      RHMapbox.centerOnMe();
    }

    if (!ResidentialListings.wasAlreadyInitialized()) {
      ResidentialListings.neighborhoodSelectize = $('#neighborhood-select-multiple').selectize({
        plugins: ['remove_button'],
        hideSelected: true,
        maxItems: 100,
        items: ResidentialListings.selectedNeighborhoodIds,
        onChange: function(value) {
          ResidentialListings.selectedNeighborhoodIds = value;
        }
      });

      $('#unit-amenities-select-multiple').selectize({
        plugins: ['remove_button'],
        hideSelected: true,
        maxItems: 100,
        items: ResidentialListings.selectedUnitAmenityIds,
        onChange: function(value) {
          ResidentialListings.selectedUnitAmenityIds = value;
        }
      });

      $('#building-amenities-select-multiple').selectize({
        plugins: ['remove_button'],
        hideSelected: true,
        maxItems: 100,
        items: ResidentialListings.selectedBuildingAmenityIds,
        onChange: function(value) {
          ResidentialListings.selectedBuildingAmenityIds = value;
        }
      });
    }
  }

  ResidentialListings.initDesktopIndex = function() {
    //$('#residential-desktop').removeClass('hidden');
    $('#residential-mobile').remove();
    Listings.hideSpinner();

    $('#residential-desktop a').click(function() {
      if ($(this).text().toLowerCase().indexOf('csv') === -1) {
        Listings.showSpinner();
      }
    });

    // main index table
    ResidentialListings.sortOnColumnClick();
    Common.markSortingColumn();
    if (Common.getSearchParam('sort_by') === '') {
      Common.markSortingColumnByElem($('th[data-sort="updated_at"]'), 'desc')
    }

    $('#residential-desktop .close').click(function() {
      Listings.hideSpinner();
    });

    if (!ResidentialListings.wasAlreadyInitialized()) {
    // var alreadyInitialized = !!$('#neighborhood-select-multiple').parent().attr('initialized');
    // if (!alreadyInitialized) {
      $('#neighborhood-select-multiple').selectize({
        plugins: ['remove_button'],
        hideSelected: true,
        maxItems: 100,
        items: ResidentialListings.selectedNeighborhoodIds,
        onChange: function(value) {
          ResidentialListings.selectedNeighborhoodIds = value;
          // console.log(ResidentialListings.selectedNeighborhoodIds);
        },
        // onBlur: ResidentialListings.throttledSearch
      });

      $('#neighborhood-select-multiple').attr('initialized', 'true');
    // }

      if (!$('#unit-amenities-select-multiple')[0].selectize) {
        $('#unit-amenities-select-multiple').selectize({
          plugins: ['remove_button'],
          hideSelected: true,
          maxItems: 100,
          items: ResidentialListings.selectedUnitAmenityIds,
          onChange: function(value) {
            ResidentialListings.selectedUnitAmenityIds = value;
          },
          // onBlur: ResidentialListings.throttledSearch
        });
      }

      if (!$('#building-amenities-select-multiple')[0].selectize) {
        $('#building-amenities-select-multiple').selectize({
          plugins: ['remove_button'],
          hideSelected: true,
          maxItems: 100,
          items: ResidentialListings.selectedBuildingAmenityIds,
          onChange: function(value) {
            ResidentialListings.selectedBuildingAmenityIds = value;
          },
          // onBlur: ResidentialListings.throttledSearch
        });
      }
    }

    // just above main listings table - selecting listings menu dropdown
    $('#emailListings').click(Listings.sendMessage);
    $('#assignListings').click(Listings.assignPrimaryAgent);
    $('#unassignListings').click(Listings.unassignPrimaryAgent);
    $('tbody').off('click', 'i', Listings.toggleListingSelection);
    $('tbody').on('click', 'i', Listings.toggleListingSelection);
    $('.select-all-listings').off('click', Listings.selectAllListings);
    $('.select-all-listings').on('click', Listings.selectAllListings);
    $('.selected-listings-menu').on('click', 'a', function() {
      var action = $(this).data('action');
      if (action in Listings.indexMenuActions) Listings.indexMenuActions[action]();
    });

    RHMapbox.initMapbox('r-big-map', ResidentialListings.buildContentString);
  }

  // called on index & show pages
  ResidentialListings.initIndex = function() {
    // do this before initializing mobile/desktop-specific js
    ResidentialListings.selectedNeighborhoodIds = Common.getURLParameterByName('neighborhood_ids');
    if (ResidentialListings.selectedNeighborhoodIds) {
      ResidentialListings.selectedNeighborhoodIds =
          ResidentialListings.selectedNeighborhoodIds.split(',');
    }

    ResidentialListings.selectedUnitAmenityIds = Common.getURLParameterByName('unit_feature_ids');
    if (ResidentialListings.selectedUnitAmenityIds) {
      ResidentialListings.selectedUnitAmenityIds =
          ResidentialListings.selectedUnitAmenityIds.split(',');
    }

    ResidentialListings.selectedBuildingAmenityIds = Common.getURLParameterByName('building_feature_ids');
    if (ResidentialListings.selectedBuildingAmenityIds) {
      ResidentialListings.selectedBuildingAmenityIds =
          ResidentialListings.selectedBuildingAmenityIds.split(',');
    }

    if (Common.onMobileDevice()) {
      ResidentialListings.initMobileIndex();
    } else {
      ResidentialListings.initDesktopIndex();
    }

    $('input').keydown(ResidentialListings.preventEnter);
    $('#res-search-trigger').click(function(e) {
      ResidentialListings.doSearch();
      e.preventDefault();
    });
  }

  ResidentialListings.initShow = function() {
    $('.carousel-indicators > li:first-child').addClass('active');
    $('.carousel-inner > .item:first-child').addClass('active');

    if(!Common.onMobileDevice()) {
      $('#footer-mobile-show').remove();
      $('.mobile-show-page-wrap').removeClass();
    } else {
      $('#footer-mobile-show').removeClass('hidden');
    }
  }

  ResidentialListings.ready = function() {
    ResidentialListings.clearTimer();

    var editPage = $('.residential_listings.edit').length;
    var newPage = $('.residential_listings.new').length;
    var indexPage = $('.residential_listings.index').length;

    // new and edit pages both render the same form template, so init them using the same code
    if (editPage || newPage) {
      ResidentialListings.initEditor();
    } else if (indexPage) {
      ResidentialListings.initIndex();
    } else {
      ResidentialListings.initShow();
    }
  };
  // Code for copy to clipboard public_url on pinup
  var clipboard = new Clipboard('.rd_copy_btn', {text: function (trigger) {
    var retrive_id = trigger.getAttribute('id');
    var find_id = trigger.getAttribute('data-clipboard-target');
    var get_href = $(find_id).attr('href');
    return get_href
  }
  });
  
  $('.rd_copy_btn').tooltip({
    trigger: 'click',
    placement: 'bottom'
  });

  function setTooltip(btn, message) {
    $(btn).tooltip('hide')
      .attr('data-original-title', message)
      .tooltip('show');
  }

  function hideTooltip(btn) {
    setTimeout(function() {
      $(btn).tooltip('hide');
    }, 1000);
  }
  clipboard.on('success', function(e) {
    setTooltip(e.trigger, 'Link copied to clipboard');
    hideTooltip(e.trigger);
  });

  clipboard.on('error', function(e) {
    setTooltip(e.trigger, 'Failed!');
    hideTooltip(e.trigger);
  });

})();

$(document).on('keyup',function(evt) {
  if (evt.keyCode == 27) {
    Listings.hideSpinner();
  }
});

// When dynamically adding open house fields through the edit form, make sure
// the calendar widget is triggered
$(document).on('fields_added.nested_form_fields', function() {
  $('.datepicker').each(function() {
    $(this).datetimepicker({
      viewMode: 'days',
      format: 'MM/DD/YYYY',
      allowInputToggle: true
    });
  });
});

document.addEventListener('turbolinks:load', ResidentialListings.ready);

document.addEventListener("turbolinks:before-cache", function() {
  $('.residential_listings').attr('initialized', 'true');
})
