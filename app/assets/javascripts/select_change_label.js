jQuery(function () {
  $( document ).ready(function() {
    $('[label_target]').each(function() {
      change_label($(this));
    })
  });

  $(document).on('change', '[label_target]', function () {
    change_label($(this));
  })

  function change_label(element) {
    var $id_label = element.attr('class_form').toLowerCase().concat('_', element.attr('label_target'));
    var $label_target = $(`label[for="${$id_label}"]`);
    if (element.find(":selected").attr('value') == element.attr('value_change_label')){  
      var $text = $label_target.text().concat(element.attr('text_append'));
    }else{
      var $text = $label_target.text().split(element.attr('text_append'))[0];
    }
    $($label_target).text($text);
  }
})


