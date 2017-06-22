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
end
