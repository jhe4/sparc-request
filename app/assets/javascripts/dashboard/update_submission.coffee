$ ->
  $('#submissionModal').on 'shown.bs.modal', ->
    $('.update-submission').on 'click', ->
      id = $(this).data('id')
      values = {}
      $.each $('.edit_submission').serializeArray(), (i, field) ->
        values[field.name] = field.value
      serviceId = values["submission[service_id]"]
      $.ajax
        url: "/services/#{serviceId}/additional_details/submissions/#{id}"
        type: 'PATCH'
        data: values
