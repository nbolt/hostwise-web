class Admin::InventoryController < Admin::AuthController
  expose(:property) { Property.find params[:id] }

  def index
    @distribution_centers = DistributionCenter.all
    distribution_centers = DistributionCenter.all
    respond_to do |format|
      format.html
      format.json do
        render json: distribution_centers.to_json
      end
    end
  end
end