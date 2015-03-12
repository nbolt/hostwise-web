class Host::PropertiesController < Host::AuthController
  expose(:property) { Property.find_by_slug params[:slug] }
  expose(:booking)  { Booking.find_by_id params[:booking] }

  def show
    respond_to do |format|
      format.html { redirect_to '/' unless property }
      format.json { render json: property.to_json(include: {property_photos: {}, active_bookings: {include: [:services], methods: [:cost]}, future_bookings: {include: [:services], methods: [:cost]}, past_bookings: {include: [:services], methods: [:cost]}}, methods: [:nickname, :short_address, :primary_photo, :full_address, :next_service_date]) }
    end
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
      render json: property.to_json(include: [:active_bookings, :future_bookings, :past_bookings, :property_photos], methods: [:nickname, :short_address, :primary_photo, :full_address])
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

  def book
    if params[:dates]
      bookings = []
      params[:dates].each do |k,v|
        if v
          v.each do |day|
            month = k.split('-')[0]
            year  = k.split('-')[1]
            date = Date.strptime("#{month}-#{year}-#{day}", '%m-%Y-%d')
            status_cd = Rails.env.production? ? 4 : 1
            booking = property.bookings.build(date: date, status_cd: status_cd)
            if params[:late_next_day].present?
              booking.late_next_day = true if date.strftime('%b %-d, %Y') == params[:late_next_day]
            end
            if params[:late_same_day].present?
              booking.late_same_day = true if date.strftime('%b %-d, %Y') == params[:late_same_day]
            end
            unless Booking.by_user(current_user)[0] || current_user.migrated
              booking.first_booking_discount = true
            end
            booking.payment = Payment.find params[:payment]
            params[:services].each do |service|
              booking.services.push Service.where(name: service)[0]
            end
            if property.bookings.empty? && current_user.vip_count < 5
              booking.vip = true
              current_user.update_attribute :vip_count, current_user.vip_count + 1
            end
            booking.save # need to check for errors
            bookings.push booking
            UserMailer.new_booking_notification(booking).then(:deliver)
            UserMailer.booking_confirmation(booking).then(:deliver) if current_user.settings(:booking_confirmation).email
          end
        end
      end
      render json: { success: true, bookings: bookings.to_json(methods: :cost) }
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
        property = current_user.properties.build(property_params)
        property.property_photos.build(photo: params[:file]) # need to background this
        unless property.valid?
          render json: { success: false, message: property.errors.full_messages[0] }
          return
        end

        # validate delivery_point_barcode and confirm with user if duplicate
        unless params[:extras][:validated]
          rsp = call_smarty(params[:form][:address1], params[:form][:address2], params[:form][:zip])
          address = rsp[0].to_hash if rsp[0]
          code = address[:delivery_point_barcode] if address
          if code
            if address[:components][:secondary_designator].present?
              address1 = address[:delivery_line_1].split(address[:components][:secondary_designator])[0].strip
              address2 = "#{address[:components][:secondary_designator]} #{address[:delivery_line_1].split(address[:components][:secondary_designator])[1].strip}"
            else
              address1 = address[:delivery_line_1]
              address2 = nil
            end
            if Property.where(address1: address1, address2: address2, zip: address[:components][:zipcode])[0]
              render json: { success: false, extras: {validated: true}, type: 'info', message: 'You may already have another property with this address. Hit next to continue.' }
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
        property.property_type_cd = params[:form][:property_type_cd]
        property.bedrooms = params[:form][:bedrooms][:id]
        property.bathrooms = params[:form][:bathrooms][:id]
        if PRICING.chain(property.property_type.to_s, property.bedrooms, property.bathrooms)
          render json: { success: true }
        else
          render json: { success: false, message: "Sorry, looks like we aren't setup for properties of this configuration. Please call support." }
        end
      when 3
        property = current_user.properties.build(property_params)
        property.step = 3
        property.active = true
        property.property_photos.build(photo: params[:file]) if params[:file].present?

        property.property_type_cd = params[:form][:property_type_cd]
        property.rental_type_cd = params[:form][:rental_type_cd]
        property.bedrooms = params[:form][:bedrooms][:id]
        property.bathrooms = params[:form][:bathrooms][:id]
        property.twin_beds = params[:form][:twin_beds][:id]
        property.full_beds = params[:form][:full_beds][:id]
        property.queen_beds = params[:form][:queen_beds][:id]
        property.king_beds = params[:form][:king_beds][:id]

        property.access_info = params[:form][:access_info]
        property.trash_disposal = params[:form][:trash_disposal]
        property.parking_info = params[:form][:parking_info]
        property.restocking_info = params[:form][:restocking_info]
        property.additional_info = params[:form][:additional_info] || '?'

        if property.save
          current_user.save
          UserMailer.property_confirmation(property).then(:deliver) if current_user.settings(:property_added).email
          render json: { success: true, slug: property.slug, id: property.id }
        else
          render json: { success: false, message: property.errors.full_messages[0] }
        end
    end
  end

  def booking_cost
    services = params[:services].map {|s| Service.where(name: s)[0] if s[1]}.compact
    cost = Booking.cost property, services
    cost[:first_booking_discount] = if Booking.by_user(current_user)[0] || current_user.migrated then false else true end
    render json: cost
  end

  def address
    rsp = call_smarty(params[:form][:address1], params[:form][:address2], params[:form][:zip])
    code = rsp[0].to_hash[:delivery_point_barcode] if rsp[0]
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
    params.require(:form).permit(:title, :address1, :address2, :zip, :phone_number, :bedrooms, :bathrooms,
                                 :twin_beds, :full_beds, :queen_beds, :king_beds, :property_type_cd, :rental_type_cd,
                                 :access_info, :parking_info, :additional_info, :trash_disposal, :restocking_info)
  end

  def call_smarty(address1, address2, zip)
    address = SmartyStreets::StreetAddressRequest.new(street: address1, street2: address2, zipcode: zip)
    return SmartyStreets::StreetAddressApi.call(address)
  end

end
