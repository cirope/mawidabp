jQuery(function () {
  $(document).ready(function () {
    $('[data-target-label]').each(function () {
      changeLabel($(this))
    })
  });

  $(document).on('change', '[data-target-label]', function () {
    changeLabel($(this))
  })

  function changeLabel(element) {
    // debugger;
    var id_label = element.data('formClass').toLowerCase().concat('_', element.data('targetLabel'))
    var $label_target = $('label[for="' + id_label + '"]');
    if (element.find(":selected").val() == element.data('targetValue')) {  
      var text = $label_target.text().concat(element.data('suffix'))
    } else {
      var text = $label_target.text().split(element.data('suffix'))[0]
    }

    $($label_target).text(text)
  }
})


