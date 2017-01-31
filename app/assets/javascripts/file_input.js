jQuery(function ($) {
  $(document).on('click', '.file-container .btn', function () {
    $(this).closest('.file-container').find('input[type="file"]').click()
  })

  $(document).on('change', 'input[type="file"]', function () {
    if ($(this).val().trim())
      $(this)
        .closest('.file-container')
        .find('span.icon')
        .removeClass('glyphicon-folder-open')
        .addClass('glyphicon-file')
  })

  $(document).on('click', 'input[type="file"]', function () {
    var attrName    = $(this).attr('name').replace(/^.*\[(\w+)\]$/, "$1")
    var $container  = $(this).closest('.file-container')
    var $cacheInput = $container.find('[name$="[' + attrName + '_cache]"]')

    if ($(this).val().trim() || $cacheInput.val()) {
      $(this).val('')
      $cacheInput.val('')

      $container.
        find('span.icon').
        removeClass('glyphicon-file').
        addClass('glyphicon-folder-open')
    }
  })
})
