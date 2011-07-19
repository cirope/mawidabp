/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */


// Funciones de autocompletado
var AutoComplete = {
  observeAll: function() {
    $('input.autocomplete_field:not([data-observed])').each(function(){
      var input = $(this);
      
      input.autocomplete({
        source: function(request, response) {
          return jQuery.ajax({
            url: input.data('autocompleteUrl'),
            dataType: 'json',
            data: {q: request.term},
            success: function(data) {
              response(jQuery.map(data, function(item) {
                  var content = $('<div>');
                  
                  content.append($('<span class="label">').text(item.label));
          
                  if(item.informal) {
                    content.append($('<span class="informal">').text(item.informal));
                  }

                  return {label: content.html(), value: item.label, item: item};
                })
              );
            }
          });
        },
        type: 'get',
        select: function(event, ui) {
          var selected = ui.item;
          
          input.val(selected.value);
          input.data('item', selected.item);
          input.next('input.autocomplete_id').val(selected.item.id);
          
          input.trigger('autocomplete:update', input);
          
          return false;
        },
        open: function() {$('.ui-menu').css('width', input.width());}
      });
      
      input.data('autocomplete')._renderItem = function(ul, item) {
        return $('<li></li>')
          .data('item.autocomplete', item)
          .append($( "<a></a>" ).html(item.label)).appendTo( ul );
      }
    }).data('observed', true);
  }
};