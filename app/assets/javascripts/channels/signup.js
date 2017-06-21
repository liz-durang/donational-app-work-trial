App.signup = App.cable.subscriptions.create('SignupChannel', {
  connected: function() {
    return this.perform('start');
  },

  disconnected: function() {
  },

  received: function(data) {
    $('.pending').remove();

    if (data.previous_response) {
      $('.messages').append('<li><span class="message is-response">' + data.previous_response + '</span></li>');
    }

    $('.messages').append('<li><span class="message typing"></span></li>');

    var cumulativeDelay = 0;

    data.messages.forEach(function(message, index, messages) {
      var previousOrFirstMessage = (index == 0) ? message : messages[index - 1];
      // Take the average length of the current message and the previous message (to give the user time to read)
      var readingDelay = 10 * (previousOrFirstMessage.length + message.length / 2);

      setTimeout(
        function() {
          $('.typing').text(message).removeClass("typing");
          if (index == messages.length - 1) {
            $('.responses').html(data.possible_responses);
            $('[data-conversation-response]').focus();
          } else {
            $('.messages').append('<li><span class="message typing"></span></li>');
          }
        },
        cumulativeDelay + readingDelay
      );

      cumulativeDelay += readingDelay;
    });
  },

  respond: function(response) {
    $('.messages').append('<li class="pending"><span class="pending message is-response">' + response + '</span></li>');
    $('.responses').html('');
    window.scrollTo(0, document.body.scrollHeight);

    this.perform('respond', { response: response });

    return;
  }
});

$(document).on('keypress', '[data-behavior-auto-submit] input[type=text]', function(event) {
  if (event.keyCode === 13) {
    App.signup.respond(event.target.value);
    return event.preventDefault();
  }
});

$(document).on('click', '[data-behavior-auto-submit] input[type=radio]', function(event) {
  App.signup.respond(event.target.value);
  return event.preventDefault();
});
