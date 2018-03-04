document.addEventListener('turbolinks:load', function() {
  function getAll(selector) {
    return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
  }

  const $tabToggles = getAll('.tabs [data-target]');
  const $tabPanels = $tabToggles.map(function($el) { return $el.dataset.target });
  const $tabActivators = getAll('[data-activate-tab][data-target]');

  if ($tabToggles.length > 0) {
    $tabToggles.forEach(function($el) {
      $el.addEventListener('click', function(e) {
        e.preventDefault();
        activateTab($el.dataset.target);
      });
    });
  }

  if ($tabActivators.length > 0) {
    $tabActivators.forEach(function($el) {
      $el.addEventListener('click', function(e) {
        e.preventDefault();
        activateTab($el.dataset.target);
      });
    });
  }

  function activateTab(tab) {
    deactivateAllToggles();
    activateToggleFor(tab);
    hideAllPanels();
    showPanel(tab);
  }

  function deactivateAllToggles() {
    $tabToggles.forEach(function($el) {
      $el.classList.remove('is-active');
    });
  }

  function activateToggleFor(tab) {
    document.querySelector(".tabs [data-target='"+tab+"']").classList.add('is-active');
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
