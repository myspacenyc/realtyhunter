class SessionsController < ApplicationController
  skip_authorize_resource
  skip_before_action :logged_in_user, only: [:new, :create, :google_auth]

  def new
    # if already logged in, just go to the correct landing page
    if current_user
      if current_user.is_external_vendor?
        redirect_to current_user
      elsif current_user.is_hired_photographer?
        redirect_to photographer_todo_path
      elsif current_user.is_roomsharing?
        redirect_to room_index_path
      else
        redirect_to residential_listings_path
      end
    end
  end

  def create
    # automatically lowercase their email and trim any whitespaces
    user = User.where(email: params[:session][:email].downcase.gsub(/\A\p{Space}*|\p{Space}*\z/, '')).first
    #puts "\n^^^^ found user #{user.inspect}"
    if user && !user.archived && user.authenticate(params[:session][:password])
      #puts "111111"
      if user.activated? && user.approved?
        #puts "222222"
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        user_home
      else
        #puts "444444"
        if !user.activated?
          #puts "55555"
          message  = "Account not activated. "
          message += "Check your email for the activation link."
        elsif !user.approved
          #puts "66666"
          message  = "Account not approved. "
          message += "Contact your company's admin if you don't receive an approval in the next 24hrs."
        else
          #puts "77777"
          message = "Something went wrong"
        end
        flash[:warning] = message
        redirect_to root_url
      end
    else
      #puts "3333333"
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end

  def user_home
    # redirect_to root_path unless current_user
    if current_user && current_user.is_external_vendor?
      redirect_to current_user
    elsif current_user.is_hired_photographer?
      redirect_to photographer_todo_path
    elsif current_user.is_roomsharing?
        redirect_to room_index_path
    elsif current_user
      redirect_to residential_listings_path
    else
      redirect_to root_path
    end
  end

  def google_auth
    @user = User.find_or_create_by(email: auth['info']['email']) do |u|
      u.name = auth['info']['name']
      u.email = auth['info']['email']
      u.company_id = 1
      u.office_id = 1
      u.streeteasy_email = 'testagent@myspacenyc.com'
      access_token = auth
      u.google_token = auth.credentials.token
      refresh_token = auth.credentials.refresh_token
      u.google_refresh_token = refresh_token if refresh_token.present?
      u.password = SecureRandom.urlsafe_base64
      u.save!
    end
    log_in @user
    redirect_to root_path
  end

  private

  def auth
    request.env['omniauth.auth'] 
  end

end
