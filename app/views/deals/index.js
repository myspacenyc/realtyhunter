// Append new data
$("<%=j render @deals %>")
  .appendTo($(".infinite-table"));
Forms.hideSpinner();

// Update pagination link
<% if @deals.last_page? %>
  $('.pagination').remove();
<% else %>
  $('.pagination')
    .html("<%=j link_to_next_page(@deals, 'Load More', remote: true) %>");
<% end %>
