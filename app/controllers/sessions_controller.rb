class SessionsController < ApplicationController
  layout 'sessions'

  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(email: params.expect(:email).to_s.strip.downcase)

    if user&.local_account? && user.authenticate(params.expect(:password).to_s)
      session[:user_id] = user.id
      redirect_to root_path, notice: "Signed in as #{user.name}."
    else
      flash.now[:alert] = 'Invalid email or password.'
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: 'Signed out.'
  end
end
