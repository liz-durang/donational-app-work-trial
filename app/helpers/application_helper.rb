module ApplicationHelper
  def sign_in_button
    link_to 'Sign in', new_sessions_path, class: 'button is-outlined'
  end

  def sign_out_button
    link_to(
      'Sign out',
      sessions_path,
      class: 'button',
      method: :delete,
      data: { confirm: 'Are you sure you want to sign out?' }
    )
  end

  def sign_in_or_out_button
    return sign_out_button if logged_in?
    sign_in_button
  end

  def icon_tag(icon, size: nil)
    content_tag(:span, class: ['icon', size.present? ? "is-#{size}" : nil] ) do
      content_tag(:i, nil, class: ['fa', icon])
    end
  end

  def icon_with_tooltip_tag(icon, text)
    content_tag(:div, class: 'dropdown is-hoverable') do
      content_tag(:div, icon_tag(icon), class: 'dropdown-trigger') +
      content_tag(:div, class: 'dropdown-menu') do
        content_tag(:div, class: 'dropdown-content') do
          content_tag(:div, text, class: 'dropdown-item')
        end
      end
    end
  end
end
