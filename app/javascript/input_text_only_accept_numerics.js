jQuery(function () {
  $('[data-input-text-only-accept-numerics]').keypress(function (e) {
    if(isNaN(Number(e.key))) {
      return false;
    }
  });
})
