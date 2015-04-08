class Admin::PropertiesController < Admin::AuthController
  expose(:property) { Property.find params[:id] }

  def index
    properties = Property.all
    respond_to do |format|
      format.html
      format.json do
        render json: properties.to_json(methods: [:neighborhood_address, :nickname, :property_size, :next_service_date, :last_service_date], include: {user: {methods: [:name]}, bookings: {}})
      end
    end
  end

end
