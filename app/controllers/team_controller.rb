class TeamController < ApplicationController

  def signout
    logout
    redirect_to '/'
  end

end
