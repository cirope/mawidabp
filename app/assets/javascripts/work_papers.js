jQuery(function ($) {
  $(document).on('keyup', '[data-work-paper-description]', function () {
    var description = $(this).val() || ''
    var urlMatch    = description.match(/(ftp|file|http|https):\/\/[\\\w\-.:%]+(\/\S*)?/)
    var fileUrl     = urlMatch && urlMatch[0]
    var url         = fileUrl && fileUrl.replace(/^\s+|\s+$/gm, '')
    var fileInput   = $(this).closest('.work_paper').find('[data-file-url]')

    if (url)
      fileInput.prop('href', url).removeClass('hidden')
    else
      fileInput.addClass('hidden')
  })

  $(document).on('dynamic-item.removed', '.work_paper', function() {
    var workPaperCode = $(this).find('input[name$="[code]"]').val()

    if(workPaperCode === lastWorkPaperCode)
      lastWorkPaperCode = lastWorkPaperCode.previous(3)
  });
})
