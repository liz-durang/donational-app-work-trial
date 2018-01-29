module ApplicationHelper
  def sign_in_button
    link_to 'Sign in', new_sessions_path, class: 'button is-outlined'
  end

  def sign_in_link
    link_to 'Sign in', new_sessions_path
  end

  def sign_out_link
    link_to(
      sessions_path,
      method: :delete,
      data: { confirm: 'Are you sure you want to sign out?' }
    ) do
      icon_tag('fa-sign-out-alt') + ' Sign out'
    end
  end

  def link_to_account
    link_to(portfolio_path) do
      icon_tag('fa-user') + current_donor.name
    end
  end

  def sign_in_button_or_account
    return link_to_account if logged_in?
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

  def display_flash_messages
    flash.map do |type, message|
      next if type == 'analytics'
      type = 'danger' if type.in? %w(alert error)

      content_tag(:article, class: ['notification', "is-#{type}"]) do
        content_tag(:p, message)
      end
    end.compact.reduce(:+)
  end
end
