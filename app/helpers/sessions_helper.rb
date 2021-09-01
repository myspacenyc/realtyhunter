module SessionsHelper
	# Logs in the given user.
  def log_in(user)
    session[:user_id] = user.id
    user.update_columns(last_login_at: Time.zone.now)
    query = Geocoder.search(params[:latlong]).first
    if !query.nil?
      UserLoginDetail.create!(login_address: query.address, login_time: Time.zone.now, user_id: user.id)
    end
  end

  # Remembers a user in a persistent session.
  def remember(user)
    user.remember
    cookies.signed[:user_id] = user.id
    cookies[:remember_token] = {
      value: user.remember_token,
      expires: 24.hours.from_now.utc
    }
  end

  # Returns the user corresponding to the remember token cookie.
  def current_user
    if (user_id = session[:user_id])
      #puts "found from session"
      @current_user ||= User.where(id: user_id).first
    elsif (user_id = cookies.signed[:user_id])
      #puts "found from cookies"
      user = User.where(id: user_id).first
      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !current_user.nil?
  end

  # Forgets a persistent session.
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
    cookies.delete(:expires)
  end

  # Logs out the current user.
  def log_out
    forget(current_user)
    # session.delete(:user_id)
    reset_session
    @current_user = nil
  end

# Redirects to stored location (or to the default).
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # Stores the URL trying to be accessed.
  def store_location
    session[:forwarding_url] = request.url if request.get?
  end

end
