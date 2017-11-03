document.addEventListener('turbolinks:load', function() {
  function getAll(selector) {
    return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
  }

  const $accordions = getAll('[data-behavior="accordion"]');
  const $accordionToggles = getAll('[data-behavior="accordion"] [data-target]');
  const $accordionPanels = $accordionToggles.map(function($el) { return $el.dataset.target });

  if ($accordionToggles.length > 0) {
    $accordionToggles.forEach(function($el) {
      $el.addEventListener('click', function() {
        const currentlyActive = $el.classList.contains('is-active');

        deactivateAllToggles();
        hideAllPanels();

        if (!currentlyActive) {
          activateToggle($el);
          showPanel($el.dataset.target);
        }
      });
    });
  }

  function deactivateAllToggles() {
    $accordionToggles.forEach(function($el) {
      $el.classList.remove('is-active');
    });
  }

  function activateToggle(el) {
    el.classList.add('is-active');
  }

  function hideAllPanels() {
    $accordionPanels.forEach(function(id) {
      document.getElementById(id).classList.add('is-hidden');
    });
  }

  function showPanel(id) {
    document.getElementById(id).classList.remove('is-hidden');
  }
});
