swal {
  title: 'Are you sure?'
  text: 'You cannot undo this action'
  type: 'warning'
  showCancelButton: true
  confirmButtonColor: '#DD6B55'
  confirmButtonText: 'Delete'
  closeOnConfirm: true
}, ->
  <% @submission.destroy %>
  $('.additional-details-submissions-panel').html("<%= j render 'submissions_panel', protocol: @protocol %>")
  $(".complete-additional-details").html("<%= j render 'additional_details/dashboard_complete_additional_details', service_request: @service_request %>")
