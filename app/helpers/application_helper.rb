require 'commonmarker'

module ApplicationHelper
  def sign_in_button
    link_to 'Sign in', new_sessions_path, class: 'button is-outlined'
  end

  def sign_in_link(css_class: nil)
    link_to 'Sign in', new_sessions_path, class: css_class
  end

  def sign_out_link(css_class: nil)
    link_to(
      sessions_path,
      method: :delete,
      data: { confirm: 'Are you sure you want to sign out?' },
      class: css_class
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

      content_tag(:article, class: ['message', "is-#{type}"]) do
        content_tag(:p, message, class: 'message-body')
      end
    end.compact.reduce(:+)
  end

  def cents_to_currency(cents)
    return '' unless cents

    dollars = (cents / 100.0).ceil
    number_to_currency(dollars, precision: 0)
  end

  def markdown_to_html(markdown)
    return '' if markdown.blank?

    CommonMarker.render_html(markdown).html_safe
  end
end
