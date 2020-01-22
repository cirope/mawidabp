jQuery(function ($) {
  if ($('.endless-pagination').length) {
    $(document).on('scroll touchmove', function () {
      var pagination = $('.pagination')
      var url        = pagination.find('.next_page a').attr('href')
      var atBottom   = $(window).scrollTop() > $(document).height() - $(window).height() - 50

      if (url && atBottom && !$.active) { // skip double call
        pagination.text($('.loading-caption').text().trim())
        $.getScript(url, function () { $(document).scroll() })
      }
    })

    $(document).scroll()
  }
})
