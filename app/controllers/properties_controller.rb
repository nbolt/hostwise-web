class PropertiesController < ApplicationController

  def build
    case params[:stage]
    when 1
      if params[:form][:city]
        property = current_user.properties.build(property_params)
      else
        render json: { success: false, message: "Please select a city" }
        return
      end
    when 2
      property = Property.find(params[:property_id])
      params[:chosen_dates].map{|k,v| v.map{|d| "#{k}-#{d}" }}.flatten.each do |date|
        nums = date.split('-'); nums[0] = nums[0].to_i + 1
        date = Date.strptime(nums.join('-'), '%m-%Y-%d')
        property.bookings.build(date: date)
      end
    when 3
      property = Property.find(params[:property_id])
      property.bookings.pending.each do |booking|
        params[:chosen_services].each do |_, service|
          service = Service.find service
          booking.services.push service
        end
      end
    when 4
      property = Property.find(params[:property_id])
      customer = Stripe::Customer.create(email: current_user.email, card: params[:stripe_token])
      payment = current_user.payments.build({
        stripe_id: customer.id,
        last4: customer.active_card.last4,
        card_type: customer.active_card.type.downcase.gsub(' ', '_'),
        fingerprint: customer.active_card.fingerprint
      })
    end
    if property.save
      current_user.save
      render json: { success: true, property_id: property.id }
    else
      render json: { success: false, message: property.errors.full_messages[0] }
    end
  end

  private

  def property_params
    params.require(:form).permit(:title, :address1, :address2)
  end

end
