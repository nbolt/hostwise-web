class PropertiesController < ApplicationController

  before_filter :require_login

  def build
    case params[:stage]
    when 1
      if params[:form][:city]
        # validate delivery_point_barcode and confirm with user if duplicate
        property = current_user.properties.build(property_params)
        city = City.find(params[:form][:city][:id])
        property.city = city.name
        property.state = city.state.abbr
      else
        render json: { success: false, message: "Please select a city" }
        return
      end
    when 2
      property = Property.find(params[:property_id])
      property.bookings.pending.destroy_all
      params[:chosen_dates].map{|k,v| v.map{|d| "#{k}-#{d}" }}.flatten.each do |date|
        nums = date.split('-'); nums[0] = nums[0].to_i + 1
        date = Date.strptime(nums.join('-'), '%m-%Y-%d')
        property.bookings.build(date: date)
      end
    when 3
      if params[:chosen_services][0]
        property = Property.find(params[:property_id])
        property.bookings.pending.each do |booking|
          params[:chosen_services].each do |_, service|
            service = Service.find service
            booking.services.push service
          end
        end
      else
        render json: { success: false, message: "Please select at least one service" }
        return
      end
    when 4
      property = Property.find(params[:property_id])
      if params[:stripe_token]
        customer = Stripe::Customer.retrieve current_user.stripe_customer_id
        card = customer.cards.create(card: params[:stripe_token])
        payment = current_user.payments.build({
          stripe_id: card.id,
          last4: card.last4,
          card_type: card.brand.downcase.gsub(' ', '_'),
          fingerprint: card.fingerprint
        })
      else
        payment = current_user.payments.where(stripe_id: params[:stripe_id])[0]
      end
      property.booking.pending.each do |booking|
        booking.payment = payment
        booking.save
      end
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
    params.require(:form).permit(:title, :address1, :address2)
  end

end
