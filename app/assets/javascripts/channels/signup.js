App.signup = App.cable.subscriptions.create('SignupChannel', {
  connected: function() {
    return this.perform('start');
  },

  disconnected: function() {
  },

  received: function(data) {
    $('.history').append(data.previous_question);
    $('.staging').html('');
    $('.current').html(data.question);
  },

  respond: function(response) {
    $('.current .response').html(response);
    $('.staging').html($('.current').html());
    $('.current').html('<p style="color: blue">&hellip;</p>');

    return this.perform('respond', { response: response });
  }
});

$(document).on('keypress', '[data-conversation-response]', function(event) {
  if (event.keyCode === 13) {
    App.signup.respond(event.target.value);
    return event.preventDefault();
  }
});

$(document).on('click', '[data-conversation-predefined-response]', function(event) {
  App.signup.respond(event.target.dataset.conversationPredefinedResponse);
  return event.preventDefault();
});
