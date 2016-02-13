ResidentialListings = {};

// TODO: break this up by controller action?

(function() {
  ResidentialListings.timer;
  ResidentialListings.announcementsTimer;
  ResidentialListings.selectedNeighborhoodIds = null;
  ResidentialListings.selectedUnitAmenityIds = null;
  ResidentialListings.selectedBuildingAmenityIds = null;

	// for searching on the index page
	ResidentialListings.doSearch = function (sortByCol, sortDirection) {
	  var search_path = $('#res-search-filters').attr('data-search-path');

	  Listings.showSpinner();

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
        pet_policy_shorthand: $('#pet_policy_shorthand').val(),
        available_starting: $('#available_starting').val(),
        available_before: $('#available_before').val(),
        status: $('#status').val(),
        has_fee: $('#has_fee').val(),
        neighborhood_ids: ResidentialListings.selectedNeighborhoodIds,
        unit_feature_ids: ResidentialListings.selectedUnitAmenityIds,
        building_feature_ids: ResidentialListings.selectedBuildingAmenityIds,
        roomsharing_filter: $('#roomsharing_filter').prop('checked'),
        unassigned_filter: $('#unassigned_filter').prop('checked'),
        primary_agent_id:  $('#primary_agent_id').val(),
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

	 	ResidentialListings.passiveRealTimeUpdate();
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

	// update the announcements every 60 seconds
	ResidentialListings.updateAnnouncements = function() {
		//console.log('updateAnnouncements ', $('#residential').length);
		if ($('#residential .announcement').length) {
			//console.log('updating ann');
			$.ajax({
	      url: '/residential_listings/update_announcements',
	    });

			ResidentialListings.announcementsTimer = setTimeout(ResidentialListings.updateAnnouncements, 60 * 1 * 1000);
		}
	};

	// if a user remains on this page for an extended amount of time,
	// refresh the page every so often. We want to make sure they are
	// always viewing the latest data.
	ResidentialListings.passiveRealTimeUpdate = function() {
    ResidentialListings.clearTimer();
    // don't update on the show page
		if ($('#residential').length) {
			// update every few minutes
		  ResidentialListings.timer = setTimeout(ResidentialListings.doSearch, 60 * 10 * 1000);
		}
	};

	// search as user types
	ResidentialListings.throttledSearch = function () {
		//clear any interval on key up
		ResidentialListings.clearTimer();
		ResidentialListings.timer = setTimeout(ResidentialListings.doSearch, 500);
	};

	// change enter key to tab
	ResidentialListings.preventEnter = function (event) {
	  if (event.keyCode == 13) {
	    return false;
	  }
	};

	// for giant google map
	ResidentialListings.buildContentString = function (key, info) {
	  var contentString = '<strong>' + key + '</strong><br />'; //<hr />';
	  for (var i=0; i<info['units'].length; i++) {
	    contentString += '<a href="https://myspace-realty-monster.herokuapp.com/residential_listings/' + info['units'][i].id + '">#' + info['units'][i].building_unit + '</a> ' + info['units'][i].beds + ' bd / '
	      + info['units'][i].baths + ' baths $' + info['units'][i].rent + '<br />';
	    if (i == 5) {
	      contentString += '<a href="https://myspace-realty-monster.herokuapp.com/residential_listings?building_id=' + info['building_id'] + '">View more...</a>';
	      break;
	    }
	  }
	  return contentString;
	};

	ResidentialListings.toggleFeeOptions = function(event) {
		var isChecked = $('#residential .has-fee').prop('checked');
		if (isChecked) {
			$('#residential .show-op').addClass('hide');
			$('#residential .show-tp').removeClass('hide');
		} else {
			$('#residential .show-op').removeClass('hide');
			$('#residential .show-tp').addClass('hide');
		}
	};

	ResidentialListings.inheritFeeOptions = function() {
		bldg_id = $('#residential #residential_listing_unit_building_id').val();

		$.ajax({
			type: 'GET',
			url: '/residential_listings/fee_options/',
			data: {
				building_id: bldg_id,
			}
		});
	};

	ResidentialListings.setPositions = function() {
	  // loop through and give each task a data-pos
	  // attribute that holds its position in the DOM
	  $('#residential .img-thumbnail').each(function(i) {
	    $(this).attr("data-pos", i+1);
	  });
	};

  ResidentialListings.sortOnColumnClick = function() {
		$('#residential .th-sortable').click(function(e) {
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
    //DropZoneHelper.updateRotateImgLinks('residential', 'residential_listings');

    $('.carousel-indicators > li:first-child').addClass('active');
    $('.carousel-inner > .item:first-child').addClass('active');

    DropZoneHelper.setPositions('residential', 'images');
    DropZoneHelper.makeSortable('residential', 'images');

    // after the order changes
    $('#residential .sortable').sortable().bind('sortupdate', function(e, ui) {
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
    $('#residential .documents.sortable').sortable().bind('sortupdate', function(e, ui) {
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
      if($('#residential_listing_cyof_true').is(":checked")){
      $("#residential_listing_commission_amount").val('0');
      $("#residential_listing_commission_amount").attr("readonly", "readonly");
    }
    $('input[name="residential_listing[cyof]"]').change(function(){
      if($(this).attr("id")=="residential_listing_cyof_true"){
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
    if($('#residential_listing_rlsny').is(":checked")){
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
    $('input[name="residential_listing[rlsny]"]').change(function(){
      if($(this).is(":checked")){
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

  ResidentialListings.initEditor = function() {
    $('#residential .has-fee').click(ResidentialListings.toggleFeeOptions);
    ResidentialListings.toggleFeeOptions();
    // when creating a new listing, inherit TP/OP from building's landlord
    $('#residential #residential_listing_unit_building_id').change(ResidentialListings.inheritFeeOptions);

    // make sure datepicker is formatted before setting initial date below
    // use in residential/edit, on photos tab
    $('.datepicker').datetimepicker({
      viewMode: 'days',
      format: 'MM/DD/YYYY',
      allowInputToggle: true
    });
    var available_by = $('#residential .datepicker').attr('data-available-by');
    if (available_by) {
      $('#residential .datepicker').data("DateTimePicker").date(available_by);
    }

    // for drag n dropping photos/docs
    // disable auto discover
    Dropzone.autoDiscover = false;
    ResidentialListings.initializeImageDropzone();
    ResidentialListings.initializeDocumentsDropzone();

    ResidentialListings.commissionAmount();
    ResidentialListings.rlsnyValidation();
  }

  ResidentialListings.initIndex = function() {
    ResidentialListings.passiveRealTimeUpdate();
    // ResidentialListings.updateAnnouncements();

    // hide spinner on main index when first pulling up the page
    document.addEventListener("page:restore", function() {
      Listings.hideSpinner();
      ResidentialListings.passiveRealTimeUpdate();
      // ResidentialListings.updateAnnouncements();
    });
    Listings.hideSpinner();

    $('#residential a').click(function() {
      Listings.showSpinner();
    });

    // main index table
    ResidentialListings.sortOnColumnClick();
    Common.markSortingColumn();
    if (Common.getSearchParam('sort_by') === '') {
      Common.markSortingColumnByElem($('th[data-sort="updated_at"]'), 'desc')
    }

    $('.close').click(function() {
      Listings.hideSpinner();
    });

    // index filtering
    $('#residential input').keydown(ResidentialListings.preventEnter);
    $('#residential #address').bind('railsAutocomplete.select', ResidentialListings.throttledSearch);
    $('#residential #address').change(ResidentialListings.throttledSearch);
    $('#residential #unit').change(ResidentialListings.throttledSearch);
    $('#residential #rent_min').change(ResidentialListings.throttledSearch);
    $('#residential #rent_max').change(ResidentialListings.throttledSearch);
    $('#residential #bed_min').change(ResidentialListings.throttledSearch);
    $('#residential #bed_max').change(ResidentialListings.throttledSearch);
    $('#residential #bath_min').change(ResidentialListings.throttledSearch);
    $('#residential #bath_max').change(ResidentialListings.throttledSearch);
    $('#residential #landlord').bind('railsAutocomplete.select', ResidentialListings.throttledSearch);
    $('#residential #landlord').change(ResidentialListings.throttledSearch);
    $('#residential #available_starting').blur(ResidentialListings.throttledSearch);
    $('#residential #available_before').blur(ResidentialListings.throttledSearch);
    $('#residential #pet_policy_shorthand').change(ResidentialListings.throttledSearch);
    $('#residential #status').change(ResidentialListings.throttledSearch);
    $('#residential #has_fee').change(ResidentialListings.throttledSearch);
    // $('#residential #neighborhood_ids').change(ResidentialListings.throttledSearch);
    // $('#residential #unit_feature_ids').change(ResidentialListings.throttledSearch);
    // $('#residential #building_feature_ids').change(ResidentialListings.throttledSearch);
    $('#residential #roomsharing_filter').change(ResidentialListings.throttledSearch);
    $('#residential #unassigned_filter').change(ResidentialListings.throttledSearch);
    $('#residential #primary_agent_id').change(ResidentialListings.throttledSearch);

    // just above main listings table - selecting listings menu dropdown
    $('#residential #emailListings').click(Listings.sendMessage);
    $('#residential #assignListings').click(Listings.assignPrimaryAgent);
    $('#residential #unassignListings').click(Listings.unassignPrimaryAgent);
    $('#residential tbody').on('click', 'i', Listings.toggleListingSelection);
    $('#residential .select-all-listings').click(Listings.selectAllListings);
    $('#residential .selected-listings-menu').on('click', 'a', function() {
      var action = $(this).data('action');
      if (action in Listings.indexMenuActions) Listings.indexMenuActions[action]();
    });

    RHMapbox.initMapbox('r-big-map', ResidentialListings.buildContentString);

    // activate tooltips
    $('[data-toggle="tooltip"]').tooltip();

    // mobile-only
    $('#residential-mobile input').keydown(ResidentialListings.preventEnter);

    ResidentialListings.selectedNeighborhoodIds = getURLParameterByName('neighborhood_ids');
    if (ResidentialListings.selectedNeighborhoodIds) {
      ResidentialListings.selectedNeighborhoodIds =
          ResidentialListings.selectedNeighborhoodIds.split(',');
    }

    $('#neighborhood-select-multiple').selectize({
      plugins: ['remove_button'],
      hideSelected: true,
      maxItems: 100,
      items: ResidentialListings.selectedNeighborhoodIds,
      onChange: function(value) {
        ResidentialListings.selectedNeighborhoodIds = value;
      }
    });

    ResidentialListings.selectedUnitAmenityIds = getURLParameterByName('unit_feature_ids');
    if (ResidentialListings.selectedUnitAmenityIds) {
      ResidentialListings.selectedUnitAmenityIds =
          ResidentialListings.selectedUnitAmenityIds.split(',');
    }
    $('#unit-amenities-select-multiple').selectize({
      plugins: ['remove_button'],
      hideSelected: true,
      maxItems: 100,
      items: ResidentialListings.selectedUnitAmenityIds,
      onChange: function(value) {
        ResidentialListings.selectedUnitAmenityIds = value;
      }
    });

    ResidentialListings.selectedBuildingAmenityIds = getURLParameterByName('building_feature_ids');
    if (ResidentialListings.selectedBuildingAmenityIds) {
      ResidentialListings.selectedBuildingAmenityIds =
          ResidentialListings.selectedBuildingAmenityIds.split(',');
    }
    $('#building-amenities-select-multiple').selectize({
      plugins: ['remove_button'],
      hideSelected: true,
      maxItems: 100,
      items: ResidentialListings.selectedBuildingAmenityIds,
      onChange: function(value) {
        ResidentialListings.selectedBuildingAmenityIds = value;
      }
    });

    $('.js-show-announcements').click(function() {
      ResidentialListings.showCard('announcements');
    });

    $('.js-show-main').click(function(e) {
      ResidentialListings.showCard('main', e);
    });

    $('.js-run-search').click(function(e) {
      ResidentialListings.showCard('main', e);
      ResidentialListings.throttledSearch();
    })

    $('.js-cancel-search').click(function(e) {
      ResidentialListings.showCard('main', e);

    })

    $('.js-mobile-filters').click(function(e) {
      ResidentialListings.showCard('mobile-filters', e);
    });
  }

  ResidentialListings.showCard = function(cardName, e) {
    $('.card.main').removeClass('card-visible');
    $('.card.announcements').removeClass('card-visible');
    $('.card.mobile-filters').removeClass('card-visible');
    $('.card.' + cardName).addClass('card-visible');

    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }
  };

})();

$(document).on('keyup',function(evt) {
  if (evt.keyCode == 27) {
  	Listings.hideSpinner();
  }
});

$(document).ready(function() {
  ResidentialListings.clearTimer();

  var url = window.location.pathname;
  var residential = url.indexOf('residential_listings') > -1;
  var editPage = url.indexOf('edit') > -1;
  var newPage = url.indexOf('new') > -1;
  if (residential) {
    // new and edit pages both render the same form template, so init them using the same code
    if (editPage || newPage) {
      ResidentialListings.initEditor();
    } else {
      ResidentialListings.initIndex();
    }
  }
});
