$('#submissionModal .modal-footer .update-submission').remove()
$('#submissionModal').modal('show')
$('#submissionModal .modal-body').html("<%= j render 'submission_info' %>")
