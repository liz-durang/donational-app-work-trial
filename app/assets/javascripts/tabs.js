document.addEventListener('DOMContentLoaded', function() {
  function getAll(selector) {
    return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
  }

  const $tabToggles = getAll('.tabs [data-target]');
  const $tabPanels = $tabToggles.map(function($el) { return $el.dataset.target });

  if ($tabToggles.length > 0) {
    $tabToggles.forEach(function($el) {
      $el.addEventListener('click', function() {
        deactivateAllToggles();
        activateToggle($el);
        hideAllPanels();
        showPanel($el.dataset.target);
      });
    });
  }

  function deactivateAllToggles() {
    $tabToggles.forEach(function($el) {
      $el.classList.remove('is-active');
    });
  }

  function activateToggle(el) {
    el.classList.add('is-active');
  }

  function hideAllPanels() {
    $tabPanels.forEach(function(id) {
      document.getElementById(id).classList.add('is-hidden');
    });
  }

  function showPanel(id) {
    document.getElementById(id).classList.remove('is-hidden');
  }
});
