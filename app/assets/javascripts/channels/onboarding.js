$(document).on('submit', 'form[data-behavior-auto-submit]', function(event) {
  event.preventDefault();
  const formData = $(this).serialize();
  App.onboarding.respond(formData);
});

$(document).on('change', '[data-behavior-auto-submit] input[type=radio]', function(event) {
  $(event.target.form).trigger('submit');
});

function createOnboardingChannel(uuid) {
  App.onboarding = App.cable.subscriptions.create({ channel: 'OnboardingChannel', room: uuid }, {
    connected: function() { this.start(); },

    disconnected: function() {},

    start: function() {
      this.clearScreen();
      this.perform('start');
    },

    received: function(data) {
      if(data.redirect_to) {
        window.location.href = data.redirect_to;
        return;
      }

      $('#question-heading').text(data.heading);

      const chatMessages = $('.chat-messages');

      let cumulativeDelay = 0;
      const readingDelay = 10;

      data.messages.forEach(function(message, index, messages) {
        if (index > 0) {
          // Give the user time to read the previous message
          cumulativeDelay += readingDelay * messages[index - 1].body.length;
        }

        let pendingMessage = $('<li class="chat-message typing appear-in"></li>')
          .addClass(message.type)
          .css({ 'animation-delay': cumulativeDelay + 'ms'})
          .appendTo(chatMessages);

        let messageText = $('<span>').text(message.body).appendTo(pendingMessage);

        // Give the user time to read the current message
        cumulativeDelay += readingDelay * message.body.length;

        setTimeout(function() { pendingMessage.removeClass('typing'); }, cumulativeDelay);
      });

      $(data.responses)
        .css({ 'animation-delay': cumulativeDelay + 500 + 'ms'})
        .addClass('appear-in')
        .appendTo('.chat-responses')
        .find('input:first-of-type')
        .focus();

      window.scrollTo(0, 0);
    },

    respond: function(serializedFormData) {
      this.clearScreen();
      this.perform('respond', { payload: serializedFormData });
    },

    clearScreen: function() {
      $('.chat-messages').html('');
      $('.chat-responses').html('');
    }
  });
}
