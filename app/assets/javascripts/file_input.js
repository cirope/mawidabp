jQuery(function ($) {
  $(document).on('change', 'input[type="file"]', function () {
    if (/([^\s])/.test($(this).val()))
      $(this)
        .closest('.file-container')
        .find('span.icon')
        .removeClass('glyphicon-folder-open')
        .addClass('glyphicon-file')
  })
})
