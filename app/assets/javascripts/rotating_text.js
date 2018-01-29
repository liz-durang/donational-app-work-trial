document.addEventListener('turbolinks:load', function () {
  $('[data-rotating-text-alternatives]').each(function() {
    var el = this;
    var $this = $(this);
    var strings = this.dataset.rotatingTextAlternatives.split('|');
    var showTime = this.dataset.rotatingTextShowTime;

    el.dataset.rotatingTextIndex = 0;

    setInterval(function() {
      el.dataset.rotatingTextIndex++;

      $this.fadeOut(500, function() {
        $this.fadeIn(500);
        el.innerHTML = strings[el.dataset.rotatingTextIndex % strings.length];
      });
    }, showTime);
  });
});
