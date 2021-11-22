Landlords = {};

(function() {
  Landlords.timer;

  Landlords.showSpinner = function() {
    $('.ll-spinner-desktop').show();
  };

  Landlords.hideSpinner = function() {
    $('.ll-spinner-desktop').hide();
  };

  Landlords.filterListings = function() {
    var search_path = $('#listings').attr('data-search-path');
    $.ajax({
      url: search_path,
      data: {
        status_listings: $('#status_listings').val(),
      },
      dataType: "script",
      success: function(data) {
        Landlords.hideSpinner();
      },
      error: function(data) {
        Landlords.hideSpinner();
      }
    });
  };

  Landlords.doSearch = function(sortByCol, sortDirection) {
    var search_path = $('#landlord-search-filters').attr('data-search-path');
    Landlords.showSpinner();

    if (!sortByCol) {
      sortByCol = Common.getSearchParam('sort_by');
    }
    if (!sortDirection) {
      sortDirection = Common.getSearchParam('direction');
    }

    var data = {
      filter: $('#filter').val(),
      status: $('#status').val(),
      rating: $('#rating').val(),
      ll_importance: $('#ll_importance').val(),
      listing_agent_id: $('#listing_agent_id').val(),
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

  Landlords.sortOnColumnClick = function() {
    $('#landlords .th-sortable').click(function(e) {
      Common.sortOnColumnClick($(this), Landlords.doSearch);
    });
  };

  // search as user types
  Landlords.throttledSearch = function() {
    Landlords.showSpinner();

    clearTimeout(Landlords.timer); // clear any interval on key up
    Landlords.timer = setTimeout(Landlords.doSearch, 500);
  };

  // change enter key to tab
  Landlords.preventEnter = function(event) {
    if (event.keyCode == 13) {
      $('#checkbox_active').focus();
      return false;
    }
  };

  // Landlords.toggleFeeOptions = function() {
  //   var isChecked = $('#landlords .has-fee').prop('checked');
  //   if (isChecked) {
  //     $('#landlords .show-op').addClass('hide');
  //     $('#landlords .show-tp').removeClass('hide');
  //   } else {
  //     $('#landlords .show-op').removeClass('hide');
  //     $('#landlords .show-tp').addClass('hide');
  //   }
  // };
  $("#landlord_is_this_a_myspacenyc_house_listing_false").click(function(){
    $("#landlord_listing_agent_id").prop("disabled", true);
    $("#landlord_listing_agent_percentage").prop("disabled", true);
  })
  $("#landlord_is_this_a_myspacenyc_house_listing_true").click(function(){
    $("#landlord_listing_agent_id").prop("disabled", false);
    $("#landlord_listing_agent_percentage").prop("disabled", false);
  })

  if($("#landlord_is_this_a_myspacenyc_house_listing_false").is(":checked")){
    $("#landlord_listing_agent_id").prop("disabled", true);
    $("#landlord_listing_agent_percentage").prop("disabled", true);
  }else{
    $("#landlord_listing_agent_id").prop("disabled", false);
    $("#landlord_listing_agent_percentage").prop("disabled", false);
  }

  Landlords.initEditor = function() {
    // $('#landlords .has-fee').click(Landlords.toggleFeeOptions);
    // Landlords.toggleFeeOptions();

    var office_address = $('#map-canvas').attr('data-address') ? $('#map-canvas').attr('data-address') : 'New York, NY, USA';
    // console.log(office_address);
    $(".autocomplete-input").geocomplete({
      map: "#map-canvas",
      location: office_address,
      details: ".details"
    }).bind("geocode:result", function(event, result){
      if (this.value == "New York, NY, USA") {
        this.value = '';
      }
    }).bind("geocode:error", function(event, result){
      // console.log(office_address, "[ERROR]: " + result);
    });
  }

  Landlords.initIndex = function() {
    Landlords.hideSpinner();
    $('#landlords a').click(function() {
      if ($(this).text().toLowerCase().indexOf('csv') === -1) {
        Landlords.showSpinner();
      }
    });

    // main index table
    Landlords.sortOnColumnClick();
    Common.markSortingColumn();
    if (Common.getSearchParam('sort_by') === '') {
      Common.markSortingColumnByElem($('th[data-sort="landlords.name"]'), 'asc')
    }

    $('#landlords #filter').bind('railsAutocomplete.select', Landlords.throttledSearch);
    $('#landlords #filter').keydown(Landlords.preventEnter);
    $('#landlords #filter').change(Landlords.throttledSearch);
    $('#landlords #status').change(Landlords.throttledSearch);
    $('#landlords #rating').change(Landlords.throttledSearch);
    $('#landlords #ll_importance').change(Landlords.throttledSearch);
    $('#landlords #listing_agent_id').change(Landlords.throttledSearch);
    $('#landlords #status_listings').change(Landlords.filterListings);
  }

  Landlords.initShow = function() {
    $('#landlords #status').change(Landlords.throttledSearch);
    $('#landlords #status_listings').change(Landlords.filterListings);
  }

  Landlords.ready = function () {
    var editPage = $('.landlords.edit').length;
    var newPage = $('.landlords.new').length;
    var indexPage = $('.landlords.index').length;
    var showPage = $('.landlords.show').length;
    // new and edit pages both render the same form template, so init them using the same code
    if (editPage || newPage) {
      Landlords.initEditor();
    } else if (indexPage) {
      Landlords.initIndex();
    } else if (showPage) {
      Landlords.initShow();
    }
  };

})();

$(document).on('keyup',function(evt) {
  if (evt.keyCode == 27) {
    Landlords.hideSpinner();
  }
});

document.addEventListener('turbolinks:load', Landlords.ready);


// var counter = 1;

// function addInput(divName, template) {  
//   var newdiv = document.createElement('div');
//   newdiv.innerHTML = document.getElementById(divName).innerHTML;
//   newdiv.className = 'added';
//   document.getElementById(template).appendChild(newdiv);
//   counter++;

//   var selectElements = document.querySelectorAll('input');
//   for (var i = 0; i < selectElements.length; i++) {
//       console.log(selectElements);
//       // selectElements[i].name = 'name' + i;
//   }
// }

// function removeInput(obj) {
//   if (obj.parentNode.className == 'added') {
//       obj.parentNode.parentNode.removeChild(obj.parentNode);
//       counter--;
//   }
// }

$(document).ready(function() {
    if ($("#total_count_contacts").val() == ""){
      var treeCount = 1;
    }
    else{
      var treeCount = $("#total_count_contacts").val();
    }
    $('.button-add').click(function(){
        //we select the box clone it and insert it after the box
        $('.box.template').clone()
                          .each(function(){
                            $("#name").last().attr("name", "name_" + treeCount);
                            $("#email").last().attr("name", "email_" + treeCount);
                            $("#phone").last().attr("name", "phone_" + treeCount);
                            $("#position").last().attr("name", "position_" + treeCount);
                          })
                          .show()
                          .removeClass("template")
                          .insertAfter(".box:last");
                          treeCount ++;
                          $("#total_count_contacts").attr("value", ""+ treeCount)
    }).trigger("click");
    
    $('.button-added').click(function(){
        //we select the box clone it and insert it after the box
        $('.box.template-for-clone').clone()
                          .each(function(){
                            $("#name").last().attr("name", "name_" + treeCount);
                            $("#email").last().attr("name", "email_" + treeCount);
                            $("#phone").last().attr("name", "phone_" + treeCount);
                            $("#position").last().attr("name", "position_" + treeCount);
                          })
                          .show()
                          .removeClass("template-for-clone")
                          .insertAfter(".box:last");
                          treeCount ++;
                          $("#total_count_contacts").attr("value", ""+ treeCount)
    }).trigger("click");
    
    $(document).on("click", ".button-remove", function() {
        $(this).closest(".box").remove();
        treeCount = treeCount - 1;
        $("#total_count_contacts").attr("value", ""+ treeCount)
    });
});

function delete_contact_from_db(id) {
  var retVal = confirm("Do you want to Delete?");
  if( retVal == true ) {
    $.ajax({
      url: "delete_contact/?ll_cont_id=" + id,
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