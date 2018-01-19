document.addEventListener('turbolinks:load', function() {
  function getAll(selector) {
    return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
  }

  const $selects = getAll('[data-behavior="allocation-select"]');
  const $warning = document.querySelector('[data-behavior="allocation-warning"]');
  const $total = document.querySelector('[data-behavior="allocation-total"]');
  const $submit = document.querySelector('[data-behavior="allocation-submit"]');

  if ($selects.length > 0) {
    $selects.forEach(function ($el) {
      $el.addEventListener('change', function () {
        var total = $selects.reduce(function(total, select) {
          return total + Number(select.value);
        }, 0);

        if (total == 100) {
          $warning.classList.add('is-hidden');
          $submit.disabled = false;
        } else {
          $warning.classList.remove('is-hidden');
          $total.innerHTML = total;
          $submit.disabled = true;
        }
      });
    });
  }
});
