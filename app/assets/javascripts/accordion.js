document.addEventListener('turbolinks:load', function() {
  function getAll(selector) {
    return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
  }

  const $accordionTriggers = getAll('[data-accordion-trigger]');
  const $accordionPanels = getAll('[data-accordion-panel-for]');

  if ($accordionTriggers.length > 0) {
    $accordionTriggers.forEach(function($el) {
      $el.addEventListener('click', function() {
        const currentlyActive = $el.classList.contains('is-active');

        deactivateAllToggles();
        hideAllPanels();

        if (!currentlyActive) {
          activateToggle($el);
          showPanel($el.dataset.accordionTrigger);
        }
      });
    });
  }

  function deactivateAllToggles() {
    $accordionTriggers.forEach(function($el) {
      $el.classList.remove('is-active');
    });
  }

  function activateToggle(el) {
    el.classList.add('is-active');
  }

  function hideAllPanels() {
    $accordionPanels.forEach(function($el) {
      $el.classList.add('is-hidden');
    });
  }

  function showPanel(id) {
    getAll('[data-accordion-panel-for="' + id + '"]').forEach(function($el) {
      $el.classList.remove('is-hidden');
    });
  }
});
