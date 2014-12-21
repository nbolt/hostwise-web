class HomeController < ApplicationController

  def index
    if logged_in?
      if current_user.properties.empty?
        redirect_to '/properties/new'
      else
        render 'home'
      end
    end
  end

  def signup
    redirect_to '/' if logged_in?
  end

  def signin
    redirect_to '/' if logged_in?
  end

  def signout
    logout
    redirect_to '/'
  end

end
