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
        alt_address: $('#alt_address').val(),
        alt_unit: $('#alt_unit').val(),
        rent_min: $('#rent_min').val(),
        rent_max: $('#rent_max').val(),
        net_min: $('#net_min').val(),
        net_max: $('#net_max').val(),
        gross_min: $('#gross_min').val(),
        gross_max: $('#gross_max').val(),
        bed_min: $('#bed_min').val(),
        bed_max: $('#bed_max').val(),
        bath_min: $('#bath_min').val(),
        bath_max: $('#bath_max').val(),
        landlord: $('#landlord').val(),
        ll_importance: $('#ll_importance').val(),
        accepts_third_party_gaurantor: $('#accepts_third_party_gaurantor').val(),
        listing_id: $('#listing_id').val(),
        pet_policy_shorthand: $('#pet_policy_shorthand').val(),
        pet_policy_shorthand_mobile: $('#pet_policy_shorthand_mobile').val(),
        available_starting: $('#available_starting').val(),
        available_before: $('#available_before').val(),
        status: $('#status').val(),
        public_url: $('#public_url').val(),
        has_fee: $('#has_fee').val(),
        roomsharing_filter: $('#roomsharing_filter').prop('checked'),
        unassigned_filter: $('#unassigned_filter').prop('checked'),
        tenant_occupied: $('#tenant_occupied').val(),
        youtube_video_url: $('#youtube_video_url').val(),
        private_youtube_video_url: $('#private_youtube_video_url').val(),
        tour_3d: $('#tour_3d').val(),
        has_stock_photos_filter: $('#has_stock_photos_filter').prop('checked'),
        no_description: $('#no_description').prop('checked'),
        exclusive_filter: $('#exclusive_filter').prop('checked'),
        no_images: $('#no_images').prop('checked'),
        pending_se: $('#pending_se').prop('checked'),
        managed_listing: $('#managed_listing').prop('checked'),
        tenant_credit_offered: $('#tenant_credit_offered').prop('checked'),
        featured: $('#featured').prop('checked'),
        past_24_hours_active: $('#past_24_hours_active').prop('checked'),
        streeteasy_filter: $('#streeteasy_filter').val(),
        streeteasy_claim: $('#streeteasy_claim').val(),
        primary_agent_id:  $('#primary_agent_id').val(),
        claim_agent_id: $('#claim_agent_id').val(),
        point_of_contact:  $('#point_of_contact').val(),
        listing_agent_id: $('#listing_agent_id').val(),
        primary_agent_for_rs: $('#primary_agent_for_rs').val(),
        building_rating: $('#building_rating').val(),
        streeteasy_eligibility: $('#streeteasy_eligibility').val(),
        parent_amenities: $('#parent_amenities').val(),
        roomfill: $('#roomfill').prop('checked'),
        working: $('#working').prop('checked'),
        private_bathroom: $('#private_bathroom').prop('checked'),
        couples_accepted: $('#couples_accepted').prop('checked'),
        third_tier: $('#third_tier').prop('checked'),
        partial_move_in: $('#partial_move_in').prop('checked'),
        parent_building_amenities: $('#parent_building_amenities').val(),
        parent_neighborhoods: $('#parent_neighborhoods').val(),
        landlord_rating: $('#landlord_rating').val(),
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
    // console.log(key);
    // console.log(info);
    var slideshowContent = '';
    if (window.location.pathname == '/residential_listings/room_index'){
      var contentString = '';
    }
    else{
      var contentString = '<div class="un-content"><strong>' + key + '</strong>';
    }

    var firstImageAdded = false;
    var imgCount = 0;
    var ct = 0
    for (var i=0; i<info['units'].length; i++) {

      unit = info['units'][i];
      
      if (unit.image) {
        if (window.location.pathname == '/residential_listings/room_index'){
          if (ct >= 1){
            contentString += '<div style="border-bottom: 1px solid #ccc; margin:15px;"></div><div style="float: left;" class="image' + (!firstImageAdded ? ' active' : '') + '">' +
            '<a href="https://realtyhunter.org:3000/rooms/'+ unit.id +
            '"><img src="' + unit.image + '" /></a>' +
            '</div>';
          }
          else{
            contentString += '<div style="float: left;" class="image' + (!firstImageAdded ? ' active' : '') + '">' +
            '<a href="https://realtyhunter.org:3000/rooms/'+ unit.id +
            '"><img src="' + unit.image + '" /></a>' +
            '</div>';
          }
        }
        else{
          slideshowContent += '<div class="image' + (!firstImageAdded ? ' active' : '') + '">' +
            '<a href="https://realtyhunter.org:3000/residential_listings/'+ unit.id +
            '"><img src="' + unit.image + '" /></a>' +
            '</div>';
        }
        firstImageAdded = true;
        imgCount++;
        ct++;
      }

      var shouldHighlightRow = imgCount == 1 && info['units'].length > 1;
      
      if (unit.public_url != null){
        var set_icon = '<input type = "radio" class = "rd_copy_btn"  id = "copylinkup_'+i+'" name = "copylink" value = '+ i +' data-clipboard-target="#copycontent_'+i+'">'
      }else{
        var set_icon = ''
      }

      if (unit.public_url_for_room != null){
        var set_iconss = '<input type = "radio" class = "rd_copy_btn"  id = "copylinkup_'+i+'" name = "copylink" value = '+ i +' data-clipboard-target="#copycontent_'+i+'"'
      }
      else{
       var set_iconss = '' 
      }

      if (window.location.pathname == '/residential_listings/room_index'){
        var rooms_url = 'https://realtyhunter.org:3000/rooms/' + unit.id
        contentString += '<div class="contentRow" style="float: left;margin-left: 10px;" '+ (shouldHighlightRow ? ' active' : '') +' style="text-align: left;"><a href=' + rooms_url + '>' + key + ', #' + unit.building_unit+ '</a> <div class="un-main-content"><div>' + unit.beds + ' beds | ' + unit.baths + ' baths </div> '+ '<div> Net: $' + unit.rent + ' | Gross: $' + unit.gross + '</div><div> Avail: ' + unit.avail + '</div></div></div>' 
        for (var j=0; j<info['rooms'][i]['a'].length; j++) {
          room = info['rooms'][i]['a'][j];
          if (room.status == 2){
            contentString += '<div class="contentRowroom" style="clear: both;text-align: left;color:#cdcdcd;margin-left: 110px;"' +'">'
            + ''+set_iconss+'disabled>'
            + '<a id = "copycontent_'+i+'" href='+unit.public_url_for_room+'></a>'
            + '' + room.name + ' - ' +
            + room.rent + '</div>';
          }
          else{
            contentString += '<div class="contentRowroom" style="clear: both;text-align: left;margin-left: 110px;"'+'">'
              + ''+set_iconss+'>'
              + '<a id = "copycontent_'+i+'" href='+unit.public_url_for_room+'></a>'
              + '' + room.name + ' - ' +
              + room.rent + '</div>';
            }
        }
      }
      else{
        contentString += '<div class="contentRow' + (shouldHighlightRow ? ' active' : '') +'">'
          + ''+set_icon+''
          + '<a id = "copycontent_'+i+'" href='+unit.public_url+'></a>'
          + '<a href="https://realtyhunter.org:3000/residential_listings/'
          + unit.id + '">#' + unit.building_unit + ' ' +
          + unit.beds + ' bd / '
          + unit.baths + ' baths $' + unit.rent + '</a></div>';
      }
      if (window.location.pathname != '/residential_listings/room_index'){
        if (i == 5) {
          contentString += '<div class="contentRow"><a href="https://realtyhunter.org:3000/buildings/'
            + info['building_id'] + '">View more...</a></div>';
          break;
        }
      }
    }
    // contentString += '<button type="button" class = "finalcopylink" >Copy Link!</button>'
    if (window.location.pathname == '/residential_listings/room_index'){
      output =
        '<div class="slideshow" style="float: left;margin-right: 10px;width: 100px;">' +
          slideshowContent +
        '</div>';
      output += '<div class="content" style="float: left;width: 300px;">' +
        contentString +
        '</div><div style="clear: both;"></div>';
      return '<div class="popup" style="text-align: left;max-height: 350px;overflow: auto;">' + output + '</div>';
    }
    else{
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
    }
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
    DropZoneHelper.updateImgOptions('residential', 'residential_listings');
    DropZoneHelper.updateImgFloorPlanOptions('residential', 'residential_listings');
    DropZoneHelper.updateImgTenantSourcedOptions('residential', 'residential_listings');

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

  var isMobileVersion = document.getElementsByClassName('specific_edit');
  if (isMobileVersion.length > 0) {
    ResidentialListings.toggleExpirationDateUI = function() {
      if ($('#residential_listing_tenant_occupied')[0].checked) {
        $('.row-is_exclusive_agreement_signed').removeClass('hidden');
      } else {
        $('.row-is_exclusive_agreement_signed').addClass('hidden');
      }
    };
  }
  else{
    ResidentialListings.toggleExpirationDateUI = function() {
      if ($('#residential_listing_unit_is_exclusive_agreement_signed')[0].checked) {
        $('.row-is_exclusive_agreement_signed').removeClass('hidden');
      } else {
        $('.row-is_exclusive_agreement_signed').addClass('hidden');
      }
    };
  }

  ResidentialListings.initEditor = function() {
    $('.has-fee').click(ResidentialListings.toggleFeeOptions);
    ResidentialListings.toggleFeeOptions();
    // when creating a new listing, inherit TP/OP from building's landlord
    $('#residential_listing_unit_building_id').change(ResidentialListings.inheritFeeOptions);
    // when toggling whether there's a signed exclusive agreement
    if(window.location.href.indexOf("specific_residential_listing") > -1) {
      var isMobileVersion = document.getElementsByClassName('specific_edit');
    }
    else
    {
      var isMobileVersion = document.getElementsByClassName('agent_edit');
    }
    if (isMobileVersion.length > 0) {
      // ResidentialListings.toggleExpirationDateUI();
      $('#residential_listing_unit_is_exclusive_agreement_signed').click(
        ResidentialListings.toggleExpirationDateUI);
    }
    else{
      ResidentialListings.toggleExpirationDateUI();
    $('#residential_listing_unit_is_exclusive_agreement_signed').click(
        ResidentialListings.toggleExpirationDateUI);
    }

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
        // Listings.showSpinner();
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

      // if (!$('#unit-amenities-select-multiple')[0].selectize) {
      //   $('#unit-amenities-select-multiple').selectize({
      //     plugins: ['remove_button'],
      //     hideSelected: true,
      //     maxItems: 100,
      //     items: ResidentialListings.selectedUnitAmenityIds,
      //     onChange: function(value) {
      //       ResidentialListings.selectedUnitAmenityIds = value;
      //     },
      //     // onBlur: ResidentialListings.throttledSearch
      //   });
      // }

      // if (!$('#building-amenities-select-multiple')[0].selectize) {
      //   $('#building-amenities-select-multiple').selectize({
      //     plugins: ['remove_button'],
      //     hideSelected: true,
      //     maxItems: 100,
      //     items: ResidentialListings.selectedBuildingAmenityIds,
      //     onChange: function(value) {
      //       ResidentialListings.selectedBuildingAmenityIds = value;
      //     },
      //     // onBlur: ResidentialListings.throttledSearch
      //   });
      // }
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
    
    var specificEditPage = $('.residential_listings.specific_edit').length;
    var agentEditPage = $('.residential_listings.agent_edit').length;
    var editPage = $('.residential_listings.edit').length;
    var newPage = $('.residential_listings.new').length;
    var indexPage = $('.residential_listings.index').length;
    var indexPageIn = $('.residential_listings.room_index').length;
    var indexPageInMedia = $('.residential_listings.media_index').length;
    var indexPageAgent = $('.residential_listings.agent_rental').length;

    // new and edit pages both render the same form template, so init them using the same code
    if (editPage || newPage || specificEditPage || agentEditPage) {
      ResidentialListings.initEditor();
    } else if (indexPage) {
      ResidentialListings.initIndex();
    }else if (indexPageIn) {
      ResidentialListings.initIndex();
    }else if (indexPageInMedia) {
      ResidentialListings.initIndex();
    }else if (indexPageAgent) {
      ResidentialListings.initIndex();
    }
    else {
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

function hide_photo_for_error_type_dropdown(){
  if (document.getElementById("feedback_category").value == "requesting new photos"){
    document.getElementById("hide-dropdown").style.display = "Block";
  }else{
    document.getElementById("hide-dropdown").style.display = "none";
  }
}

function parent_amenities_check(parent_amenity){
  var get_parent = "parent_" + parent_amenity;
  // var get_child = "child_with_parent_" + parent_amenity;

  // if (document.getElementById(get_parent).value  == parent_amenity){
    var checkboxes = document.querySelectorAll('[data-parent-id="'+ parent_amenity +'"]');
    var checked_value = [];
    if(document.getElementById(get_parent).checked == true){
      for (i = 0; i < checkboxes.length; i++) {
        checked_value.push([checkboxes[i].value]);
        checkboxes[i].checked = true;   
      }
    }
    if (document.getElementById("parent_amenities").value != ""){
      var previous_value = document.getElementById("parent_amenities").value.split(',');
      document.getElementById("parent_amenities").value = previous_value + ','+checked_value;
    }
    else{
      document.getElementById("parent_amenities").value = checked_value;
    }

    if(document.getElementById(get_parent).checked == false){
      var unchecked_value = [];
      for (i = 0; i < checkboxes.length; i++) {
        unchecked_value.push(checkboxes[i].value);
        checkboxes[i].checked = false;
      }
      var previous_unchecked_value = document.getElementById("parent_amenities").value.split(',');
      var filter_unchecked_value = previous_unchecked_value.filter(Boolean)
      var uncheck_val = filter_unchecked_value.filter(function(obj) { return unchecked_value.indexOf(obj) == -1; });
      document.getElementById("parent_amenities").value = uncheck_val;
    }

    // if (document.getElementById("parent_amenities").value != ""){
    //   var previous_value = document.getElementById("parent_amenities").value.split(',');
    //   document.getElementById("parent_amenities").value = previous_value - unchecked_value;
    // }
  // }
  // console.log(checked_value);
  // console.log(checked_value);
  // document.getElementById("parent_amenities").value = name;
}

function child_amenities_uncheck(id){
  var check_value = "child_with_parent_"+ id;
  if (document.getElementById(check_value).checked == true){
    if(document.getElementById("parent_amenities").value == ""){
      document.getElementById(check_value).checked = true
      document.getElementById("parent_amenities").value = id
    }
    else{
      document.getElementById(check_value).checked = true
      checked_value = document.getElementById("parent_amenities").value.split(',');
      document.getElementById("parent_amenities").value = checked_value + ','+id;
    }
    
  }

  if (document.getElementById(check_value).checked == false){
    if(document.getElementById("parent_amenities").value != ""){
      document.getElementById(check_value).checked = false
      var unchecked_value = document.getElementById(check_value).value;
      var previous_unchecked_value = document.getElementById("parent_amenities").value.split(',');
      var filter_unchecked_value = previous_unchecked_value.filter(Boolean)
      var uncheck_val = filter_unchecked_value.filter(function(obj) { return unchecked_value.indexOf(obj) == -1; });
      document.getElementById("parent_amenities").value = uncheck_val;
    }
  }
  // if(document.getElementById("parent_amenities").value == ""){
  //   var check_value = "child_with_parent_"+ id;
  //   document.getElementById(check_value).checked = true
  //   document.getElementById("parent_amenities").value = id
  // }

  // if(document.getElementById("parent_amenities").value != ""){
    
  // }

}

function click_naked_apt(id){
  var checked_id = "residential_listing_" + id;
  var get_checked_checkbox = document.getElementById(checked_id).checked
  if (get_checked_checkbox){
    $.ajax({
      type: 'GET',
      url: '/residential_listings/claim/' +id,
    });  
  }
  else{
   $.ajax({
      type: 'GET',
      url: '/residential_listings/disclaim/' +id,
    }); 
  }
}

function parent_neighborhoods_check(parent_amenity){
  var get_parent = "parent_" + parent_amenity;
  // var get_child = "child_with_parent_" + parent_amenity;

  // if (document.getElementById(get_parent).value  == parent_amenity){
    var checkboxes = document.querySelectorAll('[data-parent-id="'+ parent_amenity +'"]');
    var checked_value = [];
    if(document.getElementById(get_parent).checked == true){
      for (i = 0; i < checkboxes.length; i++) {
        checked_value.push([checkboxes[i].value]);
        checkboxes[i].checked = true;   
      }
    }
    if (document.getElementById("parent_neighborhoods").value != ""){
      var previous_value = document.getElementById("parent_neighborhoods").value.split(',');
      document.getElementById("parent_neighborhoods").value = previous_value + ','+checked_value;
    }
    else{
      document.getElementById("parent_neighborhoods").value = checked_value;
    }

    if(document.getElementById(get_parent).checked == false){
      var unchecked_value = [];
      for (i = 0; i < checkboxes.length; i++) {
        unchecked_value.push(checkboxes[i].value);
        checkboxes[i].checked = false;
      }
      var previous_unchecked_value = document.getElementById("parent_neighborhoods").value.split(',');
      var filter_unchecked_value = previous_unchecked_value.filter(Boolean)
      var uncheck_val = filter_unchecked_value.filter(function(obj) { return unchecked_value.indexOf(obj) == -1; });
      document.getElementById("parent_neighborhoods").value = uncheck_val;
    }

    // if (document.getElementById("parent_amenities").value != ""){
    //   var previous_value = document.getElementById("parent_amenities").value.split(',');
    //   document.getElementById("parent_amenities").value = previous_value - unchecked_value;
    // }
  // }
  // console.log(checked_value);
  // console.log(checked_value);
  // document.getElementById("parent_amenities").value = name;
}

function child_neighborhoods_uncheck(id){
  var check_value = "child_with_parent_neghb_"+ id;
  if (document.getElementById(check_value).checked == true){
    if(document.getElementById("parent_neighborhoods").value == ""){
      document.getElementById(check_value).checked = true
      document.getElementById("parent_neighborhoods").value = id
    }
    else{
      document.getElementById(check_value).checked = true
      checked_value = document.getElementById("parent_neighborhoods").value.split(',');
      document.getElementById("parent_neighborhoods").value = checked_value + ','+id;
    }
    
  }

  if (document.getElementById(check_value).checked == false){
    if(document.getElementById("parent_neighborhoods").value != ""){
      document.getElementById(check_value).checked = false
      var unchecked_value = document.getElementById(check_value).value;
      var previous_unchecked_value = document.getElementById("parent_neighborhoods").value.split(',');
      var filter_unchecked_value = previous_unchecked_value.filter(Boolean)
      var uncheck_val = filter_unchecked_value.filter(function(obj) { return unchecked_value.indexOf(obj) == -1; });
      document.getElementById("parent_neighborhoods").value = uncheck_val;
    }
  }
  // if(document.getElementById("parent_amenities").value == ""){
  //   var check_value = "child_with_parent_"+ id;
  //   document.getElementById(check_value).checked = true
  //   document.getElementById("parent_amenities").value = id
  // }

  // if(document.getElementById("parent_amenities").value != ""){
    
  // }

}

function parent_building_amenities_check(parent_amenity){
  var get_parent = "parent_" + parent_amenity;
  // var get_child = "child_with_parent_" + parent_amenity;

  // if (document.getElementById(get_parent).value  == parent_amenity){
    var checkboxes = document.querySelectorAll('[data-parent-id="'+ parent_amenity +'"]');
    var checked_value = [];
    if(document.getElementById(get_parent).checked == true){
      for (i = 0; i < checkboxes.length; i++) {
        checked_value.push([checkboxes[i].value]);
        checkboxes[i].checked = true;   
      }
    }
    if (document.getElementById("parent_building_amenities").value != ""){
      var previous_value = document.getElementById("parent_building_amenities").value.split(',');
      document.getElementById("parent_building_amenities").value = previous_value + ','+checked_value;
    }
    else{
      document.getElementById("parent_building_amenities").value = checked_value;
    }

    if(document.getElementById(get_parent).checked == false){
      var unchecked_value = [];
      for (i = 0; i < checkboxes.length; i++) {
        unchecked_value.push(checkboxes[i].value);
        checkboxes[i].checked = false;
      }
      var previous_unchecked_value = document.getElementById("parent_building_amenities").value.split(',');
      var filter_unchecked_value = previous_unchecked_value.filter(Boolean)
      var uncheck_val = filter_unchecked_value.filter(function(obj) { return unchecked_value.indexOf(obj) == -1; });
      document.getElementById("parent_building_amenities").value = uncheck_val;
    }

    // if (document.getElementById("parent_amenities").value != ""){
    //   var previous_value = document.getElementById("parent_amenities").value.split(',');
    //   document.getElementById("parent_amenities").value = previous_value - unchecked_value;
    // }
  // }
  // console.log(checked_value);
  // console.log(checked_value);
  // document.getElementById("parent_amenities").value = name;
}

function select_all_building_amenities(source){
  checkboxes = document.getElementsByName('building_features[]');
  sel_all = ""
  for(var i=0, n=checkboxes.length;i<n;i++) {
    checkboxes[i].checked = source.checked;
    if (checkboxes[i].checked){
      sel_all += checkboxes[i].value + ",";
    }
    else{
     sel_all = "";
    }
    document.getElementById("parent_building_amenities").value = sel_all.replace(/,(?=[^,]*$)/, '');
  }
}

function select_all_unit_amenities(source){
  checkboxes = document.getElementsByName('unit_features[]');
  unit_all = ""
  for(var i=0, n=checkboxes.length;i<n;i++) {
    checkboxes[i].checked = source.checked;
    if (checkboxes[i].checked){
      unit_all += checkboxes[i].value + ",";
    }
    else{
     unit_all = "";
    }
    document.getElementById("parent_amenities").value = unit_all.replace(/,(?=[^,]*$)/, '');
  }
}

function child_building_amenities_uncheck(id){
  var check_value = "child_with_parent_building_"+ id;
  if (document.getElementById(check_value).checked == true){
    if(document.getElementById("parent_building_amenities").value == ""){
      document.getElementById(check_value).checked = true
      document.getElementById("parent_building_amenities").value = id
    }
    else{
      document.getElementById(check_value).checked = true
      checked_value = document.getElementById("parent_building_amenities").value.split(',');
      document.getElementById("parent_building_amenities").value = checked_value + ','+id;
    }
    
  }

  if (document.getElementById(check_value).checked == false){
    if(document.getElementById("parent_building_amenities").value != ""){
      document.getElementById(check_value).checked = false
      var unchecked_value = document.getElementById(check_value).value;
      var previous_unchecked_value = document.getElementById("parent_building_amenities").value.split(',');
      var filter_unchecked_value = previous_unchecked_value.filter(Boolean)
      var uncheck_val = filter_unchecked_value.filter(function(obj) { return unchecked_value.indexOf(obj) == -1; });
      document.getElementById("parent_building_amenities").value = uncheck_val;
    }
  }
  // if(document.getElementById("parent_amenities").value == ""){
  //   var check_value = "child_with_parent_"+ id;
  //   document.getElementById(check_value).checked = true
  //   document.getElementById("parent_amenities").value = id
  // }

  // if(document.getElementById("parent_amenities").value != ""){
    
  // }

}

function pet_policy_check(id){
  var check_value = "parent_"+ id;
  if (document.getElementById(check_value).checked == true){
    if(document.getElementById("pet_policy_shorthand").value == ""){
      document.getElementById(check_value).checked = true
      document.getElementById("pet_policy_shorthand").value = id
    }
    else{
      document.getElementById(check_value).checked = true
      checked_value = document.getElementById("pet_policy_shorthand").value.split(',');
      document.getElementById("pet_policy_shorthand").value = checked_value + ','+id;
    }
    
  }

  if (document.getElementById(check_value).checked == false){
    if(document.getElementById("pet_policy_shorthand").value != ""){
      document.getElementById(check_value).checked = false
      var unchecked_value = document.getElementById(check_value).value;
      var previous_unchecked_value = document.getElementById("pet_policy_shorthand").value.split(',');
      var filter_unchecked_value = previous_unchecked_value.filter(Boolean)
      var uncheck_val = filter_unchecked_value.filter(function(obj) { return unchecked_value.indexOf(obj) == -1; });
      document.getElementById("pet_policy_shorthand").value = uncheck_val;
    }
  }
  // if(document.getElementById("parent_amenities").value == ""){
  //   var check_value = "child_with_parent_"+ id;
  //   document.getElementById(check_value).checked = true
  //   document.getElementById("parent_amenities").value = id
  // }

  // if(document.getElementById("parent_amenities").value != ""){
    
  // }

}


var $contents = $(".test_c")
var $headers = $(".test_p").click(function () {

    var $header = $(this);
    //getting the next element
    var $content = $header.next();
    //open up the content needed - toggle the slide- if visible, slide up, if not slidedown.
    $content.stop(true, true).slideToggle(500, function () {
        //execute this after slideToggle is done
        // //change text of header based on visibility of content div
        // $header.text(function () {
        //     //change text based on condition
        //     return $content.is(":visible") ? "Collapse" : "Expand";
        // });
    });

    // $headers.not($header).text("Expand");
    $contents.not($content).stop(true, true).slideUp();
});

// $(document).ready(function() {
//     if ($("#total_count_contacts").val() == ""){
//       var treeCount = 1;
//     }
//     else{
//       var treeCount = $("#total_count_contacts").val();
//     }
//     $('.button-add').click(function(){
//         //we select the box clone it and insert it after the box
//         $('.box.template').clone()
//                           .each(function(){
//                             $("#name").last().attr("name", "name_" + treeCount);
//                             $("#email").last().attr("name", "email_" + treeCount);
//                             $("#phone").last().attr("name", "phone_" + treeCount);
//                           })
//                           .show()
//                           .removeClass("template")
//                           .insertAfter(".box:last");
//                           treeCount ++;
//                           $("#total_count_contacts").attr("value", ""+ treeCount)
//     }).trigger("click");
    
//     $('.button-added').click(function(){
//         //we select the box clone it and insert it after the box
//         $('.box.template-for-clone').clone()
//                           .each(function(){
//                             $("#name").last().attr("name", "name_" + treeCount);
//                             $("#email").last().attr("name", "email_" + treeCount);
//                             $("#phone").last().attr("name", "phone_" + treeCount);
//                           })
//                           .show()
//                           .removeClass("template-for-clone")
//                           .insertAfter(".box:last");
//                           treeCount ++;
//                           $("#total_count_contacts").attr("value", ""+ treeCount)
//     }).trigger("click");
    
//     $(document).on("click", ".button-remove", function() {
//         $(this).closest(".box").remove();
//         treeCount = treeCount - 1;
//         $("#total_count_contacts").attr("value", ""+ treeCount)
//     });
// });

function delete_contact_from_db(id) {
  var retVal = confirm("Do you want to Delete?");
  if( retVal == true ) {
    $.ajax({
      url: "delete_contact/?tenant_info_id=" + id,
      type: 'GET',
      success: function(result){
    }});
      var cls = ".del_cont_" + id
      $(cls).remove(); 
      return true;
  } else {
    return false;
  }
}

function clearsearchdata(){
  $("#address").val("");
  $("#unit").val("");
  $("#rent_min").val("");
  $("#rent_max").val("");
  $("#net_min").val("");
  $("#net_max").val("");
  $("#gross_min").val("");
  $("#gross_max").val("");
  $("#bed_min").val("Any");
  $("#bed_min").val("Any");
  $("#bath_min").val("Any");
  $("#bath_min").val("Any");
  $("#landlord").val("");
  $("#ll_importance").val("Any");
  $("#accepts_third_party_gaurantor").val("Any");
  $("#status").val("Active");
  $("#public_url").val("");
  $("#has_fee").val("Any");
  $("input:checkbox").prop('checked',false);
  $("#pet_policy_shorthand").val("");
  $("#point_of_contact").val("");
  $("#primary_agent_id").val("");
  $("#streeteasy_filter").val("Any");
  $("#streeteasy_claim").val("Any");
  $("#streeteasy_eligibility").val("Any");
  $("#tenant_occupied").val("Any");
  $("#youtube_video_url").val("Any");
  $("#tour_3d").val("Any");
  $("#available_starting").val("");
  $("#available_before").val("");
  $("#parent_neighborhoods").val("");
  $("#parent_amenities").val("");
  $("#parent_building_amenities").val("");
}