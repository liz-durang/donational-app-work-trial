document.addEventListener('turbolinks:load', function () {
  function getAll(selector) {
    return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
  }

  getAll('[type="date"]').forEach(function($el) {
    bulmaCalendar.attach($el, { overlay: true, minDate: $el.min, maxDate: $el.max });
  });
});
