class Admin::PropertiesController < Admin::AuthController
  include CsvHelper
  expose(:property) { Property.find params[:id] }

  def index
    properties = Property.all
    properties = properties.within_market(current_user.market) if current_user.market
    respond_to do |format|
      format.html
      format.json do
        render json: properties.to_json(methods: [:neighborhood_address, :nickname, :property_size, :next_service_date, :last_service_date, :linen_handling, :turnover_rate], include: {user: {methods: [:name]}, bookings: {methods: [:cost]}})
      end
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to '/' unless property }
      format.json { render json: property.to_json(include: {property_photos: {}, bookings: {}, active_bookings: {include: [:services], methods: [:cost]}, past_bookings: {include: [:services], methods: [:cost]}}, methods: [:nickname, :short_address, :primary_photo, :full_address, :next_service_date, :beds]) }
    end
  end

  def export
    properties = Property.all
    properties = properties.within_market(current_user.market) if current_user.market
    respond_to do |format|
      format.csv { send_data property_csv(properties), filename: 'properties.csv' }
    end
  end

  def notes
    @property = Property.find(params[:id])
  end

  def new_note
    property_id = params[:id]
    comment = params[:comment]
    user_id = current_user.id
    Property.find(property_id).comments.create(comment: comment, user_id: user_id)
    redirect_to "/properties/#{property.id}/notes"
  end

  def update
    params[:form] = JSON.parse params[:form] if params[:form].class == String

    property.twin_beds = params[:form][:twin_beds][:id]
    property.full_beds = params[:form][:full_beds][:id]
    property.queen_beds = params[:form][:queen_beds][:id]
    property.king_beds = params[:form][:king_beds][:id]
    property.bedrooms = params[:form][:bedrooms][:id]
    property.bathrooms = params[:form][:bathrooms][:id]

    property.assign_attributes property_params
    property.step = 3
    if params[:file]
      property.property_photos.build(photo: params[:file])
      if property.valid?
        property.property_photos.destroy_all # make sure the uploaded photo is good before deleting previous one
        property.property_photos.build(photo: params[:file])
      end
    end

    if !PRICING.chain(property.property_type.to_s, property.bedrooms, property.bathrooms)
      render json: { success: false, message: "Sorry, looks like we aren't setup for properties of this configuration. Please call support." }
      return
    end

    if property.save
      render json: property.to_json(include: [:active_bookings, :past_bookings, :property_photos], methods: [:nickname, :short_address, :primary_photo, :full_address])
    else
      render json: { success: false, message: property.errors.full_messages[0] }
    end
  end

  def upload
    if params[:file]
      preview = PhotoPreview.new(photo: params[:file])
      if preview.save
        render json: { success: true, image: preview.photo.url }
      else
        render json: { success: false, message: preview.errors.full_messages[0] }
      end
    end
  end

  def deactivate
    property.update_attribute :active, false
    render json: { success: true }
  end

  def reactivate
    property.update_attribute :active, true
    render json: { success: true }
  end

  private

  def property_params
    params.require(:form).permit(:title, :address1, :address2, :zip, :phone_number, :bedrooms, :bathrooms,
                                 :twin_beds, :full_beds, :queen_beds, :king_beds, :property_type_cd, :rental_type_cd,
                                 :access_info, :parking_info, :additional_info, :trash_disposal, :restocking_info)
  end
end
