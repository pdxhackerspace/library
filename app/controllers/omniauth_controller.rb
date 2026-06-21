class OmniauthController < ApplicationController
  def callback
    auth = request.env['omniauth.auth']
    OidcDebug.log_auth(auth)
    user = User.from_omniauth(auth)

    if user
      session[:user_id] = user.id
      granted_scopes = OidcScopes.granted_scopes(auth).join(' ')
      OidcDebug.log(
        "Signed in user #{user.id} (#{user.email}) scopes=#{granted_scopes} " \
        "admin=#{user.admin?} editor=#{user.editor?}"
      )
      redirect_to root_path, notice: "Signed in as #{user.name}."
    else
      OidcDebug.log('OIDC sign-in did not return an email address.')
      redirect_to login_path, alert: 'OIDC sign-in did not return an email address.'
    end
  end

  def failure
    OidcDebug.log_failure(request.env)
    redirect_to login_path, alert: "Sign-in failed: #{params[:message] || 'unknown error'}"
  end
end
