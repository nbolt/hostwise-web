class ContractorController < ApplicationController

  def signout
    logout
    redirect_to '/'
  end

end
