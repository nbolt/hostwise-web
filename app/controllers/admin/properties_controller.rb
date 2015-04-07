class Admin::PropertiesController < Admin::AuthController
  expose(:property) { Property.find params[:id] }

  def index
    properties = Property.all
    respond_to do |format|
      format.html
      format.json do
        render json: properties.to_json(methods: [:neighborhood_address, :nickname], include: {user: {methods: [:name]}})
      end
    end
  end

end
