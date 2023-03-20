jQuery(function ($) {
  var clearFile = function ($fileInput) {
    // var attrName    = $fileInput.attr('name').replace(/^.*\[(\w+)\]$/, "$1")
    var $container  = $fileInput.closest('.file-container')
    // var $cacheInput = $container.find('[name$="[' + attrName + '_cache]"]')
    
    // if ($fileInput.val() || $cacheInput.val()) {
    if ($fileInput.val()) {
      $fileInput.val('')
      // $cacheInput.val('')

      $container.
        find('i.fas').
        removeClass('fa-file').
        addClass('fa-folder-open')

      // var targetShowFilesSelected = $fileInput.data('targetShowFilesSelected')

      // if (targetShowFilesSelected){
      //   $(targetShowFilesSelected).empty();

      //   $(targetShowFilesSelected).append('<li>'+ $fileInput.data('legendFilesEmpty') +'</li>');
      // }
    }
  }

  $(document).on('click', '.file-container .btn', function () {
    $(this).closest('.file-container').find('input[type="file"]').click()
  })

  $(document).on('change', 'input[type="file"]', function () {
    if ($(this).val().trim()) {
      var $container = $(this).closest('.file-container')

      $container.
        find('i.fas').
        removeClass('fa-folder-open').
        addClass('fa-file')

      // $container.next('[data-clear-file]').
      //   removeAttr('hidden')

      // var targetShowFilesSelected = $($(this).data('targetShowFilesSelected'))

      // if (targetShowFilesSelected){
      //   targetShowFilesSelected.empty();

      //   (Array.from($(this).get(0).files)).forEach(file => targetShowFilesSelected.append('<li>' + file.name + '</li>'));
      // }
    }
  })

  $(document).on('click', 'input[type="file"]', function () {
    clearFile($(this))
  })

  // $(document).on('click', '[data-clear-file]', function (event) {
  //   event.preventDefault()

  //   var inputName  = $(this).data('clearFile')
  //   var $container = $(this).prev('.file-container')
  //   var $fileInput = $container.find('input[name$="[' + inputName + ']"]')

  //   clearFile($fileInput)

  //   $(this).attr('hidden', true)
  // })
})
