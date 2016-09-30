<% if @submission.destroy %>
$('.additional-details-submissions-panel').html("<%= j render 'submissions_panel', protocol: @protocol %>")
$(".complete-additional-details").html("<%= j render 'additional_details/dashboard_complete_additional_details', service_request: @service_request %>")
<% else %>
swal("Error", "Submission could not be deleted", "error")
<% end %>
