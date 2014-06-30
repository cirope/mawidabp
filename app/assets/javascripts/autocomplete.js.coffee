jQuery ($) ->
  $(document).on 'change', '.ui-autocomplete-input', ->
    $($(this).data('autocompleteIdTarget')).val '' unless $(this).val()

  $(document).on 'focus', '[data-autocomplete-url]:not(.ui-autocomplete-input)', ->
    input = $ this

    input.autocomplete
      source: (request, response) ->
        $.ajax
          url: input.data('autocompleteUrl')
          dataType: 'json'
          data: $.extend({ q: request.term }, input.data('autocompleteParams'))
          success: (data)->
            response $.map data, (item) ->
              content = $('<div></div>')

              content.append $('<span></span>').text(item.label)
              content.append $('<span class="text-muted"></span>').html(item.informal) if item.informal

              label: content.html(), value: item.label, item: item
      type: 'get'
      minLength: input.data('autocompleteMinLength')
      select: (event, ui) ->
        selected = ui.item

        input.val selected.value
        input.data 'item', selected.item
        $(input.data('autocompleteIdTarget')).val selected.item.id

        input.trigger 'autocomplete:update', input

        false
      open: -> $('.ui-menu').css 'width', input.outerWidth()

    input.data('ui-autocomplete')._renderItem = (ul, item) ->
      $('<li></li>').data('item.autocomplete', item).append($('<a></a>').html(item.label)).appendTo(ul)
