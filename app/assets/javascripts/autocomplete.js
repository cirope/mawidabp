jQuery(function ($) {
  $(document).on('keyup', '.ui-autocomplete-input', function () {
    if (! $(this).val())
      $($(this).data('autocompleteIdTarget')).val('')
  })

  $(document).on('focus', '[data-autocomplete-url]:not(.ui-autocomplete-input)', function () {
    var $input = $(this)

    $input.autocomplete({
      source: function (request, response) {
        $.ajax({
          url: $input.data('autocompleteUrl'),
          dataType: 'json',
          data: $.extend({ q: request.term }, $input.data('autocompleteParams')),
          success: function (data) {
            var items = $.map(data, function (item) {
              var $content = $('<div></div>')

              $content.append($('<span></span>').text(item.label))

              if (item.informal)
                $content.append($('<span class="text-muted"></span>').html(item.informal))

              return {
                label: $content.html(),
                value: item.label,
                item:  item
              }
            })

            response(items)
          }
        })
      },
      type: 'get',
      minLength: $input.data('autocompleteMinLength'),
      select: function (event, ui) {
        var selected = ui.item

        $($input.data('autocompleteIdTarget')).val(selected.item.id)

        $input
          .val(selected.value)
          .data('item', selected.item)
          .trigger('autocomplete:update', $input)

        return false
      },
      open: function () {
        $('.ui-menu').css('width', $input.outerWidth())
      }
    })

    $input.data('ui-autocomplete')._renderItem = function (ul, item) {
      return $('<li></li>')
        .data('item.autocomplete', item)
        .append($('<a></a>').html(item.label))
        .appendTo(ul)
    }
  })
})
