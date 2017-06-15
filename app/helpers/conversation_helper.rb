module ConversationHelper
  def conversation_bubble_tag(text, from_user: false)
    if from_user
      content_tag :p, class: 'has-text-right' do
        content_tag :span, text, class: ['has-text-right', 'tag', 'is-medium', 'is-info']
      end
    else
      content_tag :p do
        content_tag :span, text, class: ['tag', 'is-medium', 'is-primary']
      end
    end
  end
end
