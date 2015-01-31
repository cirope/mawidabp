jQuery ($) ->
  $(document).on 'change', '#best_practice_obsolete', (event) ->
    $('[type="checkbox"][name$="[obsolete]"]').prop 'checked', $(this).prop('checked')

  $(document).on 'change', '[data-process-control]', (event) ->
    id = $(this).data 'processControl'

    $("[data-process-control-id=\"#{id}\"]").prop 'checked', $(this).prop('checked') if id
