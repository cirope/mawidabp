jQuery(function ($) {
  $(document).on('change', '[data-opening-interview-review-url]', function (event) {
    var $review = $(this)
    var url     = $review.data('openingInterviewReviewUrl')

    $review.prop('disabled', true)

    $.ajax({
      url:      url,
      dataType: 'script',
      data:     { review_id: $review.val() }
    }).done(function () {
      $review.prop('disabled', false)
    })
  })
})
