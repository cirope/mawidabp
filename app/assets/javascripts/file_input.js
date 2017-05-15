jQuery(function ($) {
  var clearFile = function ($fileInput) {
    var attrName    = $fileInput.attr('name').replace(/^.*\[(\w+)\]$/, "$1")
    var $container  = $fileInput.closest('.file-container')
    var $cacheInput = $container.find('[name$="[' + attrName + '_cache]"]')

    if ($fileInput.val() || $cacheInput.val()) {
      $fileInput.val('')
      $cacheInput.val('')

      $container.
        find('span.icon').
        removeClass('glyphicon-file').
        addClass('glyphicon-folder-open')
    }
  }

  $(document).on('click', '.file-container .btn', function () {
    $(this).closest('.file-container').find('input[type="file"]').click()
  })

  $(document).on('change', 'input[type="file"]', function () {
    if ($(this).val().trim()) {
      var $container = $(this).closest('.file-container')

      $container.
        find('span.icon').
        removeClass('glyphicon-folder-open').
        addClass('glyphicon-file')

      $container.next('[data-clear-file]').
        removeClass('hidden')
    }
  })

  $(document).on('click', 'input[type="file"]', function () {
    clearFile($(this))
  })

  $(document).on('click', '[data-clear-file]', function (event) {
    event.preventDefault()

    var inputName  = $(this).data('clearFile')
    var $container = $(this).prev('.file-container')
    var $fileInput = $container.find('input[name$="[' + inputName + ']"]')

    clearFile($fileInput)

    $(this).addClass('hidden')
  })
})
