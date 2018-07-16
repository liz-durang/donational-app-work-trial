// Sticky Nav Component
var Sticky = (function() {
  'use strict';

  var Sticky = {
    element: null,
    position: 0,
    addEvents: function() {
      window.addEventListener('scroll', this.onScroll.bind(this));
    },
    init: function(element) {
      this.element = element;
      this.position = element.offsetTop;
      this.placeholderElement = document.createElement('div');
      this.placeholderElement.style.height = element.offsetHeight + 'px';
      this.placeholderElement.style.display = 'none';
      this.element.parentNode.insertBefore(this.placeholderElement, this.element);
      this.addEvents();
      this.onScroll();
    },
    onScroll: function(event) {
      if (this.position < window.scrollY) {
        this.element.classList.add('is-fixed');
        this.placeholderElement.style.display = 'block';
      } else {
        this.element.classList.remove('is-fixed');
        this.placeholderElement.style.display = 'none';
      }
    }
  };

  return Sticky;
})();

document.addEventListener('turbolinks:load', function () {
  var sticky = document.querySelector('.is-sticky');
  if (sticky) { Sticky.init(sticky); }
});
