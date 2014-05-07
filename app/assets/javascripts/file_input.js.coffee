jQuery ($) ->
  $(document).on 'click', 'a.file', ->
    $(this).closest('.file_container').find('input[type="file"]').click()
    return false

  $(document).on 'change', 'input[type="file"]', ->
    $(this).closest('.file_container').find('span.icon').
      removeClass('glyphicon-folder-open').addClass('glyphicon-file')
