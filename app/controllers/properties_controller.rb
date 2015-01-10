class PropertiesController < ApplicationController
  before_filter :require_login

  expose(:property) { Property.find_by_slug params[:slug] }

  def show
    respond_to do |format|
      format.html { redirect_to '/' unless property }
      format.json { render json: property.to_json(include: :bookings) }
    end
  end

  def update
    property.assign_attributes property_params
    if property.save
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def cancel
    booking = property.bookings.find params[:booking]
    booking.destroy
    if booking.destroyed?
      render json: { success: true }
    else
      render json: { success: false }
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
      city = City.find(params[:form][:city][:id])
      state = city.state.abbr
      city = city.name

      unless params[:extras][:validated]
        code = delivery_code(params[:form][:address1], params[:form][:address2], city, state)
        if code
          if Property.where(delivery_point_barcode: code)[0]
            render json: { success: false, extras: {validated: true}, type: 'info', message: "Our records indicate you may already have a property at this address. Click 'Next' again if you still wish to continue." }
            return
          end
        else
          render json: { success: false, message: "Invalid address" }
          return
        end
      end

      property = current_user.properties.build(property_params)
      property.city = city
      property.state = state
      property.bedrooms = params[:form][:bedrooms][:id]
      property.beds = params[:form][:beds][:id]
      property.accommodates = params[:form][:accommodates][:id]
      property.property_photos.build(photo: params[:file]) # need to background this

      UserMailer.property_confirmation(property).then(:deliver)
    when 2
      property = Property.find(params[:property_id])
      property.access_info = params[:form][:access_info]
      property.trash_disposal = params[:form][:trash_disposal]
      property.parking_info = params[:form][:parking_info]
      property.additional_info = params[:form][:additional_info]
    when 3
      property = Property.find(params[:property_id])
      if params[:stripe_token]
        customer = Stripe::Customer.retrieve current_user.stripe_customer_id
        card = customer.cards.create(card: params[:stripe_token])
        existing_payment = current_user.payments.where(fingerprint: card.fingerprint)[0]
        if existing_payment
          payment = existing_payment
          customer.cards.retrieve(card.id).delete
        else
          payment = current_user.payments.create({
            stripe_id: card.id,
            last4: card.last4,
            card_type: card.brand.downcase.gsub(' ', '_'),
            fingerprint: card.fingerprint
          })
        end
      else
        payment = current_user.payments.where(stripe_id: params[:stripe_id])[0]
      end
      payment.update_attribute :property_id, property.id
    end
    if property.save
      current_user.save
      render json: { success: true, property_id: property.id }
    else
      render json: { success: false, message: property.errors.full_messages[0] }
    end
  end

  private

  def not_authenticated
    redirect_to '/signin'
  end

  def property_params
    params.require(:form).permit(:title, :address1, :address2, :bedrooms, :beds, :accommodates)
  end

  def delivery_code(address1, address2, city, state)
    address = SmartyStreets::StreetAddressRequest.new(street: address1, street2: address2, city: city, state: state)
    rsp = SmartyStreets::StreetAddressApi.call(address)
    if rsp[0]
      rsp[0].to_hash[:delivery_point_barcode]
    else
      false
    end
  end

end
