class HomeController < ApplicationController
  layout 'default'

  def index
    redirect_to home_path if logged_in?
  end

  def signup
    redirect_to home_path if logged_in?
  end

  def signin
    redirect_to home_path if logged_in?
  end

  def signout
    logout
    redirect_to root_path
  end

  def user
    render json: current_user.to_json(methods: :avatar, include: [:properties, :payments])
  end

end
