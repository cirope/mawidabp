jQuery ($) ->
  $(document).on 'change', '[data-autocomplete-url]', ->
    $($(this).data('autocompleteIdTarget')).val '' if $(this).val()

  $(document).on 'focus', '[data-autocomplete-url]:not([data-observed])', ->
    input = $(this)

    input.autocomplete
      source: (request, response) ->
        params = { q: request.term }

        if(extra = input.data('autocompleteParams'))
          params = $.extend({}, params, extra)

        $.ajax
          url: input.data('autocompleteUrl')
          dataType: 'json'
          data: params
          success: (data)->
            response $.map data, (item) ->
              content = $('<div></div>')

              content.append $('<span class="title"></span>').text(item.label)

              if item.informal
                content.append $('<span class="text-muted"></span>').html(item.informal)

              { label: content.html(), value: item.label, item: item }
      type: 'get'
      minLength: input.data('autocompleteMinLength')
      select: (event, ui) ->
        selected = ui.item

        input.val(selected.value)
        input.data('item', selected.item)
        $(input.data('autocompleteIdTarget')).val(selected.item.id)

        input.trigger 'autocomplete:update', input

        false
      open: -> $('.ui-menu').css('width', input.outerWidth())

    input.data('ui-autocomplete')._renderItem = (ul, item) ->
      $('<li></li>').data('item.autocomplete', item).append(
        $('<a></a>').html(item.label)
      ).appendTo(ul)
  .attr('data-observed', true)
