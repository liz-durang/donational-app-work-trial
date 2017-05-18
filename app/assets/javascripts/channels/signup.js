App.signup = App.cable.subscriptions.create('SignupChannel', {
  connected: function() {
    return this.perform('start');
  },

  disconnected: function() {
  },

  received: function(data) {
    console.log(data)
    // Called when there's incoming data on the websocket for this channel
    if (data['success'] == true) {
      if (data['previous_question_html'] !== null) {
        $('.history').append('<p style="color: blue">' + data['previous_question_html'] + '</p>');
      }
      if (data['previous_answer_html'] !== null) {
        $('.history').append('<p>' + data['previous_answer_html'] + '</p>');
      }
      $('.staging .response, .staging .question').html('');
      $('.current .question').html('<p>' + data['question_html'].join('<p></p>') + '</p>');
      $('.current .response').html(data['responses_html']);
    }
  },

  submit_answer: function(answer, questionId) {
    $('.staging .question').html($('.current .question').html())
    $('.current .question').html('...');
    $('.staging .response').html('<p>' + answer + '</p>');
    $('.current .response').html('');

    return this.perform('submit_question', { answer: answer, question_id: questionId });
  }
});

$(document).on('keypress', '.current .response', function(event) {
  if (event.keyCode === 13) {
    App.signup.submit_answer(event.target.value, $(event.target).data('questionId'));
    return event.preventDefault();
  }
});
