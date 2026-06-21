class OmniauthController < ApplicationController
  def callback
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)

    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "Signed in as #{user.name}."
    else
      redirect_to login_path, alert: 'OIDC sign-in did not return an email address.'
    end
  end

  def failure
    redirect_to login_path, alert: "Sign-in failed: #{params[:message] || 'unknown error'}"
  end
end
