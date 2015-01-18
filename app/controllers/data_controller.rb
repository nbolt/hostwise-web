class DataController < ApplicationController

  def cities
    render json: City.search(params[:term]).to_json(methods: :state, include: :county)
  end

  def services
    render json: Service.all
  end

  def properties
    render json: Property.by_user(current_user).search(params[:term], params[:sort]).to_json(include: [:property_photos], methods: [:primary_photo, :nickname, :short_address])
  end

  def payments
    render json: current_user.payments
  end

end
