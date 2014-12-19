class HomeController < ApplicationController

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
