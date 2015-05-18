class Host::PropertiesController < Host::AuthController
  expose(:property) { Property.find_by_slug params[:slug] }
  expose(:booking)  { Booking.find_by_id params[:booking] }

  def show
    respond_to do |format|
      format.html { redirect_to '/' unless property }
      format.json { render json: property.to_json(include: {property_photos: {}, bookings: {}, active_bookings: {include: [:services], methods: [:cost]}, past_bookings: {include: [:services], methods: [:cost]}}, methods: [:nickname, :short_address, :primary_photo, :full_address, :next_service_date, :beds]) }
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

  def book
    payment = Payment.find params[:payment]
    if current_user.transactions.empty? || current_user.transactions[-1].failed?
      begin
        Stripe::Charge.create(
          amount: 100,
          currency: 'usd',
          customer: current_user.stripe_customer_id,
          source: payment.stripe_id,
          statement_descriptor: "HostWise Preauth"[0..21], # 22 characters max
          metadata: { preauth: true, user_id: current_user.id },
          capture: false
        )
      rescue Stripe::CardError
        render json: { success: false, message: "There is a problem with your card, please contact us is the problem persists." }
        return
      end
    end
    if params[:dates]
      bookings = []
      coupon = Coupon.find params[:coupon_id] if params[:coupon_id]
      params[:dates].each do |k,v|
        if v
          v.each do |day|
            month = k.split('-')[0]
            year  = k.split('-')[1]
            date = Date.strptime("#{month}-#{year}-#{day}", '%m-%Y-%d')
            booking = property.bookings.build(date: date, timeslot: params[:timeslot], linen_handling_cd: params[:handling] || property.linen_handling_cd)
            property.update_attribute :linen_handling_cd, params[:handling] if params[:handling]
            unless booking.duplicate?
              if params[:late_next_day].present?
                booking.late_next_day = true if date.strftime('%b %-d, %Y') == params[:late_next_day]
              end
              if params[:late_same_day].present?
                booking.late_same_day = true if date.strftime('%b %-d, %Y') == params[:late_same_day]
              end
              if params[:extra_instructions].present?
                booking.extra_instructions = params[:extra_instructions]
              end
              if params[:extra_king_sets].present?
                booking.extra_king_sets = params[:extra_king_sets]
              end
              if params[:extra_twin_sets].present?
                booking.extra_twin_sets = params[:extra_twin_sets]
              end
              if params[:extra_toiletry_sets].present?
                booking.extra_toiletry_sets = params[:extra_toiletry_sets]
              end
              unless Booking.by_user(current_user)[0] || current_user.migrated
                booking.first_booking_discount = true
              end
              booking.payment = payment
              params[:services].each do |service|
                booking.services.push Service.where(name: service)[0]
              end
              if property.bookings.count == 0 && current_user.vip_count < VIP_CLEANINGS
                booking.vip = true
                current_user.update_attribute :vip_count, current_user.vip_count + 1
              end
              cost = Booking.cost(property, booking.services, booking.timeslot, booking.extra_king_sets, booking.extra_twin_sets, booking.extra_toiletry_sets, booking.first_booking_discount, booking.late_next_day, booking.late_same_day, booking.no_access_fee)
              if coupon && (coupon.limit == 0 || coupon.applied(current_user) < coupon.limit)
                booking.coupons.push coupon
                cost = Booking.cost(property, booking.services, booking.timeslot, booking.extra_king_sets, booking.extra_twin_sets, booking.extra_toiletry_sets, booking.first_booking_discount, booking.late_next_day, booking.late_same_day, booking.no_access_fee, coupon.id)
              end
              booking.timeslot_cost               = cost[:timeslot_cost] || 0
              booking.contractor_service_cost     = cost[:contractor_service_cost] || 0
              booking.cleaning_cost               = cost[:cleaning] || 0
              booking.linen_cost                  = cost[:linens] || 0
              booking.toiletries_cost             = cost[:toiletries] || 0
              booking.pool_cost                   = cost[:pool] || 0
              booking.patio_cost                  = cost[:patio] || 0
              booking.windows_cost                = cost[:windows] || 0
              booking.staging_cost                = cost[:preset] || 0
              booking.no_access_fee_cost          = cost[:no_access_fee] || 0
              booking.late_next_day_cost          = cost[:late_next_day] || 0
              booking.late_same_day_cost          = cost[:late_same_day] || 0
              booking.first_booking_discount_cost = cost[:first_booking_discount] || 0
              booking.extra_king_sets_cost        = cost[:extra_king_sets] || 0
              booking.extra_twin_sets_cost        = cost[:extra_twin_sets] || 0
              booking.extra_toiletry_sets_cost    = cost[:extra_toiletry_sets] || 0
              booking.coupon_cost                 = cost[:coupon_cost] || 0
              booking.save # need to check for errors
              booking.job.handle_distribution_jobs booking.job.primary_contractor if booking.job.primary_contractor
              bookings.push booking
              UserMailer.new_booking_notification(booking).then(:deliver)
              UserMailer.booking_confirmation(booking).then(:deliver) if current_user.settings(:booking_confirmation).email
              blast booking if booking.date <= Date.today + 2.weeks
            end
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

        zip = ZipCode.serviced.where(code: params[:form][:zip]).first
        unless zip
          UnservicedZip.create(code: params[:zip], email: current_user.email)
          render json: { success: false, message: 'Zip code is not within our area of service' }
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

            if params[:form][:title].present? && Property.where(title: params[:form][:title])[0]
              render json: { success: false, extras: {validated: true}, type: 'info', message: 'You already have a property with this nick name.' }
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
    if booking
      cost = Booking.cost property, services, booking.timeslot, params[:extra_king_sets], params[:extra_twin_sets], params[:extra_toiletry_sets], booking.first_booking_discount, booking.late_next_day, booking.late_same_day, booking.no_access_fee, booking.chain(:coupons, :first, :id) || params[:coupon_id]
      render json: cost
    else
      discount = if Booking.by_user(current_user)[0] || current_user.migrated then false else true end
      discount_cost = Booking.cost property, services, params[:timeslot], params[:extra_king_sets], params[:extra_twin_sets], params[:extra_toiletry_sets], discount
      cost = Booking.cost property, services, params[:timeslot], params[:extra_king_sets], params[:extra_twin_sets], params[:extra_toiletry_sets]
      cost[:first_booking_discount_cost] = discount_cost[:first_booking_discount]
      render json: cost
    end
  end

  def last_services
    booking = property.bookings.where(status_cd: [1,4]).order(:created_at)[-1]
    if booking
      if booking.services.empty? || booking.services.where(name: 'preset')[0]
        render json: { services: Service.standard }
      else
        render json: { services: booking.services }
      end
    else
      render json: { services: Service.standard }
    end
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

  def blast(booking)
    if booking.job
      User.available_contractors(booking).each do |contractor|
        UserMailer.new_open_job(contractor, booking.job).then(:deliver) if contractor.settings(:new_open_job).email
        TwilioJob.perform_later("+1#{contractor.phone_number}", "New HostWise Job! $#{booking.job.payout(contractor)} in #{booking.property.city}, #{booking.property.zip} on #{booking.formatted_date}.") if contractor.settings(:new_open_job).sms
      end
    end
  end
end
