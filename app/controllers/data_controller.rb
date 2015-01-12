class DataController < ApplicationController

  def cities
    render json: City.search(params[:term]).to_json(methods: :state, include: :county)
  end

  def services
    render json: Service.all
  end

  def properties
    render json: current_user.properties.sort_by{ |property| property.title.downcase }
  end

  def payments
    render json: current_user.payments
  end

end
