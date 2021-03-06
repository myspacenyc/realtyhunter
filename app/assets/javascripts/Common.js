Common = {};

(function() {
  // commonInits should run on every page load, even with turbolinks enabled
  Common.miscInits = function () {
    // initialize our dropzone widgets manually,
    Dropzone.autoDiscover = false;

    // change all date input fields to auto-open the calendar
    $('.datepicker').each(function() {
      $(this).datetimepicker({
        viewMode: 'days',
        format: 'MM/DD/YYYY',
        allowInputToggle: true
      });
    });
    $('.datepicker').each(function() {
      var date_value = $(this).attr('data-available-by');
      if (date_value) {
        $(this).data("DateTimePicker").date(date_value);
      }
    });

    $('input[type=number]').mousewheel(function(){
      event.preventDefault();
    });

    // submit login form on enter
    $('#session_password').keydown(function(e) {
        if (e.keyCode == 13) {
          $(this).closest('form').submit();
        }
    });

    // .modal-backdrop classes
    $(".modal-transparent").on('show.bs.modal', function () {
      setTimeout( function() {
        $(".modal-backdrop").addClass("modal-backdrop-transparent");
      }, 0);
    });
    $(".modal-transparent").on('hidden.bs.modal', function () {
      $(".modal-backdrop").addClass("modal-backdrop-transparent");
    });

    $(".modal-fullscreen").on('show.bs.modal', function () {
      setTimeout( function() {
        $(".modal-backdrop").addClass("modal-backdrop-fullscreen");
      }, 0);
    });
    $(".modal-fullscreen").on('hidden.bs.modal', function () {
      $(".modal-backdrop").addClass("modal-backdrop-fullscreen");
    });

    Common.detectPhoneNumbers();

    // navbar
    var sideslider = $('[data-toggle=collapse-side]');
    var sel = sideslider.attr('data-target');
    var sel2 = sideslider.attr('data-target-2');
    sideslider.click(function(event){
      $(sel).toggleClass('in');
      $(sel2).toggleClass('out');
    });

    if (Common.onMobileDevice()) {
      $('.navbar-desktop').remove();
    } else {
      $('.navbar-mobile').remove();
    }

    // disbled due to issues when navigating backwards in turbolinks
    //Common.reinitInfiniteScroll();
  };

  // disabling infinite scroll due to issues when navigating backwards in turbolinks
  // todo: check at a future date to see if the issue has been resolved
  Common.reinitInfiniteScroll = function () {
    // console.log("RE-INIT");
    $(window).unbind('scroll');
    $('#infinite-table-container').infinitePages({
      debug: true,
      buffer: 200,
      loading: function() {
        // console.log("Loading...");
        return $(this).text("Loading...");
      },
      success: function() {
        // console.log('success!');
      },
      error: function() {
        // console.log("Trouble! Please drink some coconut water and click again");
        return $(this).text("Error. Please reload page to scroll");
      }
    });
  }

  Common.getURLParameterByName = function (name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
      results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
  }

  Common.onMobileDevice = function() {
    // does not include iPad
    return /Android|webOS|iPhone|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  }

  // any phone #'s listed in 'access info' on main index pg should
  // be automatically detected
  Common.detectPhoneNumbers = function () {
    var countrycodes = "1"
    var delimiters = "-|\\.|—|–|&nbsp;"
    var phonedef = "\\+?(?:(?:(?:" + countrycodes + ")(?:\\s|" + delimiters + ")?)?\\(?[2-9]\\d{2}\\)?(?:\\s|" + delimiters + ")?[2-9]\\d{2}(?:" + delimiters + ")?[0-9a-z]{4})"
    var spechars = new RegExp("([- \(\)\.:]|\\s|" + delimiters + ")","gi") //Special characters to be removed from the link
    var phonereg = new RegExp("((^|[^0-9])(href=[\"']tel:)?((?:" + phonedef + ")[\"'][^>]*?>)?(" + phonedef + ")($|[^0-9]))","gi")

    function ReplacePhoneNumbers(oldhtml) {
      //Created by Jon Meck at LunaMetrics.com - Version 1.0
      var newhtml = oldhtml.replace(/href=['"]callto:/gi,'href="tel:')
      newhtml = newhtml.replace(phonereg, function ($0, $1, $2, $3, $4, $5, $6) {
          if ($3) return $1;
          else if ($4) return $2+$4+$5+$6;
          else return $2+"<a href='tel:"+$5.replace(spechars,"")+"'>"+$5+"</a>"+$6; });
      return newhtml;
    }

    $('.js-phoneNumber').map(function() {
      $(this).html(ReplacePhoneNumbers($(this).html()))
    });
  };

  Common.getSearchParam = function(paramName) {
    var idx = -1,
      startIdx = -1,
      endIdx = -1,
      searchStr = window.location.search,
      retVal = '';

    idx = searchStr.indexOf(paramName);
    if (idx > -1) {
      startIdx = searchStr.indexOf('=', idx+1);
      endIdx = searchStr.indexOf('&', idx+1);
      retVal = endIdx === -1 ? searchStr.slice(startIdx+1) : searchStr.slice(startIdx+1, endIdx);
    }

    return retVal;
  };

  Common.sortOnColumnClick = function(elem, callback) {
    var sortDirection = '',
        sortByCol = null;

    if (elem.hasClass('selected-sort')) {
      // switch sort order
      var i = $('.selected-sort i');
      if (i) {
        if (i.hasClass('glyphicon glyphicon-triangle-bottom')) {
          i.removeClass('glyphicon glyphicon-triangle-bottom').addClass('glyphicon glyphicon-triangle-top');
          sortDirection = 'asc';
        }
        else if (i.hasClass('glyphicon glyphicon-triangle-top')) {
          i.removeClass('glyphicon glyphicon-triangle-top').addClass('glyphicon glyphicon-triangle-bottom');
          sortDirection = 'desc';
        }
      }
    } else {
      // remove selection from old row
      $('.selected-sort').attr('data-direction', '');
      $('th i').remove(); // remove arrows
      $('.selected-sort').removeClass('selected-sort');
      // select new column
      elem.addClass('selected-sort').append(' <i class="glyphicon glyphicon-triangle-bottom"></i>');
      sortDirection = 'desc';
    }

    sortByCol = elem.attr('data-sort');
    elem.attr('data-direction', sortDirection);
    callback(sortByCol, sortDirection);
  };

  Common.markSortingColumnByElem = function(columnElem, direction) {
    if (direction === 'asc') {
      columnElem.addClass('selected-sort').append(' <i class="glyphicon glyphicon-triangle-top"></i>');
    } else {
      columnElem.addClass('selected-sort').append(' <i class="glyphicon glyphicon-triangle-bottom"></i>');
    }

    columnElem.attr('data-direction', direction);
  };

  // sets column sort UI from search params
  Common.markSortingColumn = function() {
    var searchStr = window.location.search,
        direction = '',
        sortByCol = '',
        columnElem = null,
        idx = -1,
        startIdx = -1,
        endIdx = -1;

    idx = searchStr.indexOf('sort_by');
    if (idx > -1) {
      startIdx = searchStr.indexOf('=', idx+1);
      endIdx = searchStr.indexOf('&', idx+1);
      sortByCol = endIdx === -1 ? searchStr.slice(startIdx+1) : searchStr.slice(startIdx+1, endIdx);
    }

    idx = searchStr.indexOf('direction');
    if (idx > -1) {
      startIdx = searchStr.indexOf('=', idx+1);
      endIdx = searchStr.indexOf('&', idx+1);
      direction = endIdx === -1 ? searchStr.slice(startIdx+1) : searchStr.slice(startIdx+1, endIdx);
    }

    columnElem = $('th[data-sort="' + sortByCol + '"]');
    Common.markSortingColumnByElem(columnElem, direction);
  };

})();
