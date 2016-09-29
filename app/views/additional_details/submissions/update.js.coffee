<% if @submission.save %>
  swal("Success!", "Submission saved", "success")
  $('#submissionModal').modal('hide')
<% else %>
  swal("Error", "Submission did not save, check the form for errors", "error")
  $('#submissionModal .modal-body').html("<%= j render 'edit_form' %>")
<% end %>
