jQuery(function ($) {
  $(document).on('change', '[data-corrective-actions-update-url]', function () {
    var url = $(this).data('correctiveActionsUpdateUrl')

    $('[data-corrective-actions-update-url]').prop('disabled', true)

    $.ajax({
      url:      url,
      dataType: 'script',
      data:     {
        conclusion:         $('#conclusion_draft_review_conclusion').val(),
        affects_compliance: $('#conclusion_draft_review_affects_compliance').is(':checked')
      }
    }).done(function () {
      $('[data-corrective-actions-update-url]').prop('disabled', false)
    })
  })
})
