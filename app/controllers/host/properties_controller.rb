class Host::PropertiesController < Host::AuthController
  expose(:property) { Property.find_by_slug params[:slug] }
  expose(:booking)  { Booking.find_by_id params[:booking] }

  def show
    respond_to do |format|
      format.html { redirect_to '/' unless property }
      format.json { render json: property.to_json(include: [:bookings, :property_photos], methods: [:nickname, :short_address, :primary_photo, :full_address]) }
    end
  end

  def update
    if params[:file]
      property.property_photos.destroy_all
      property.property_photos.build(photo: params[:file])
    else
      property.assign_attributes property_params
    end
    property.property_type = params[:form][:property_type][:id] if params[:form] && params[:form][:property_type]
    property.rental_type = params[:form][:rental_type][:id] if params[:form] && params[:form][:rental_type]

    if property.save
      render json: { success: true }
    else
      render json: { success: false }
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

  def book
    if params[:dates]
      params[:dates].each do |k,v|
        v.each do |day|
          month = k.split('-')[0].to_i + 1
          year  = k.split('-')[1]
          booking = property.bookings.build(date: Date.strptime("#{month}-#{year}-#{day}", '%m-%Y-%d'))
          booking.payment = Payment.find params[:payment]
          params[:services].each do |service|
            booking.services.push Service.where(name: service)[0]
          end
          booking.save # need to check for errors
        end
      end
      render json: { success: true }
    else
      render json: { success: false, message: 'Please select at least one service date' }
    end
  end

  def build
    if params[:form].class == String
      params[:form]   = JSON.parse params[:form]
      params[:extras] = JSON.parse params[:extras]
      params[:stage] = params[:stage].to_i
    end

    case params[:stage]
    when 1
      # validate delivery_point_barcode and confirm with user if duplicate
      unless params[:extras][:validated]
        code = delivery_code(params[:form][:address1], params[:form][:address2], params[:form][:zip])
        if code
          if Property.where(delivery_point_barcode: code)[0]
            render json: { success: false, extras: {validated: true}, type: 'info', message: "Our records indicate you may already have a property at this address. Click 'Next' again if you still wish to continue." }
            return
          end
        else
          render json: { success: false, message: 'Invalid address' }
          return
        end
      end
      render json: { success: true }
    when 2
      property = current_user.properties.build(property_params)
      property.active = true

      property.property_type = params[:form][:property_type][:id]
      property.rental_type = params[:form][:rental_type][:id]
      property.bedrooms = params[:form][:bedrooms][:id]
      property.bathrooms = params[:form][:bathrooms][:id]
      property.twin_beds = params[:form][:twin_beds][:id]
      property.full_beds = params[:form][:full_beds][:id]
      property.queen_beds = params[:form][:queen_beds][:id]
      property.king_beds = params[:form][:king_beds][:id]
      property.property_photos.build(photo: params[:file]) # need to background this

      property.access_info = params[:form][:access_info]
      property.trash_disposal = params[:form][:trash_disposal]
      property.parking_info = params[:form][:parking_info]
      property.additional_info = params[:form][:additional_info]

      if property.save
        current_user.save
        UserMailer.property_confirmation(property).then(:deliver)
        render json: { success: true }
      else
        render json: { success: false, message: property.errors.full_messages[0] }
      end
    end
  end

  def address
    code = delivery_code(params[:form][:address1], params[:form][:address2], params[:form][:zip])
    unless code
      render json: { success: false, message: 'Invalid address' }
      return
    end
    render json: { success: true }
  end

  def first
    redirect_to '/properties/new' unless current_user.properties.empty?
  end

  private

  def property_params
    params.require(:form).permit(:title, :address1, :address2, :zip, :bedrooms, :bathrooms,
                                :twin_beds, :full_beds, :queen_beds, :king_beds, :property_type, :rental_type,
                                :access_info, :parking_info, :additional_info, :trash_disposal)
  end

  def delivery_code(address1, address2, zip)
    address = SmartyStreets::StreetAddressRequest.new(street: address1, street2: address2, zipcode: zip)
    rsp = SmartyStreets::StreetAddressApi.call(address)
    if rsp[0]
      rsp[0].to_hash[:delivery_point_barcode]
    else
      false
    end
  end

end
