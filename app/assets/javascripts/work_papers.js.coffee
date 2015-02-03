jQuery ($) ->
  $(document).on 'keyup', '[data-work-paper-description]', ->
    description = $(this).val() || ''
    urlMatch    = description.match /(ftp|file|http|https):\/\/[\\\w\-.%]+(\/\S*)?/
    fileUrl     = urlMatch && urlMatch[0]
    fileInput   = $(this).closest('.work_paper').find '[data-file-url]'

    if fileUrl
      url = fileUrl.replace(/^\s+|\s+$/gm, '')

      fileInput.prop('href', url).removeClass 'hidden'
    else
      fileInput.addClass 'hidden'
