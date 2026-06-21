class TestSessionsController < ApplicationController
  def create
    raise 'Test sign-in is only available in test' unless Rails.env.test?

    user = User.find(params.expect(:user_id))
    session[:user_id] = user.id
    redirect_to root_path
  end
end
