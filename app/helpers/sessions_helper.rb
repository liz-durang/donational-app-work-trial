module SessionsHelper
  def state_meta_tag
    state = SecureRandom.hex(24)
    session['omniauth.state'] = state

    tag('meta', name: 'state', content: state)
  end
end
