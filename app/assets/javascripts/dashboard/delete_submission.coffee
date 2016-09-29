$ ->
  $('.delete-submission').on 'click', ->
    serviceId = $(this).data('service-id')
    id = $(this).data('id')
    protocolId = $(this).data('protocol-id')
    swal {
      title: 'Are you sure?'
      text: 'You cannot undo this action'
      type: 'warning'
      showCancelButton: true
      confirmButtonColor: '#DD6B55'
      confirmButtonText: 'Delete'
      closeOnConfirm: false
    }, ->
      $.ajax
        type: 'DELETE'
        url: "/services/#{serviceId}/additional_details/submissions/#{id}?protocol_id=#{protocolId}"
        success: ->
          swal 'Success', 'Submission deleted', 'success'
