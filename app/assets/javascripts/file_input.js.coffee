jQuery ($) ->
  $(document).on 'change', 'input[type="file"]', ->
    if /([^\s])/.test $(this).val()
      $(this).closest('.file-container').find('span.icon').
        removeClass('glyphicon-folder-open').addClass('glyphicon-file')
