$ ->
  $('tr.submission').css('cursor', 'pointer')

  $('tr.submission').on 'click', ->
    submissionId = $(this).data('id')
    serviceId = $(this).data('service-id')
    $.ajax
      type: 'GET'
      url: "/services/#{serviceId}/additional_details/submissions/#{submissionId}"

