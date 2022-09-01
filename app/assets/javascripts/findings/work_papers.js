+function () {
  $(document).on('ajax:before', '[data-add-param="last_work_paper_code"]', function (event) {
    var $a     = $(event.currentTarget)
    var params = jQuery.param({ last_work_paper_code: lastWorkPaperCode })

    $a.attr('data-params', params).attr('hidden', true)
  })
}()
