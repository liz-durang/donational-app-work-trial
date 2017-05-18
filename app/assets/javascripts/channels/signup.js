App.signup = App.cable.subscriptions.create('SignupChannel', {
  connected: function() {
  },

  disconnected: function() {
  },

  received: function(data) {
    // Called when there's incoming data on the websocket for this channel
    if (data['success'] == true) {
      $('#conversational-form .history').append('<p style="color: blue">' + data['previous_question_html'] + '</p>')
      $('#conversational-form .history').append('<p>' + data['previous_answer_html'] + '</p>')
      $('#conversational-form .staging-area').html('')
      $('#conversational-form .question').html('<p>' + data['question_html'] + '</p>')
      $('#conversational-form .responses').html(data['responses_html'])
    }
  },

  submit_answer: function(answer) {
    $('#conversational-form .question').html('')
    $('#conversational-form .responses').html('')
    $('#conversational-form .staging-area').append('<p style="color: blue">What is your name?</p>')
    $('#conversational-form .staging-area').append('<p>' + answer + '</p>')

    return this.perform('submit_question', { answer: answer });
  }
});

$(document).on('keypress', '#conversational-form .responses', function(event) {
  if (event.keyCode === 13) {
    App.signup.submit_answer(event.target.value);
    return event.preventDefault();
  }
});
