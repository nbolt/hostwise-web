class Host::PaymentsController < Host::AuthController
  expose(:payment) { Payment.find params[:id] }

  def add
    begin
      first_payment = !current_user.payments.active.present?

      if params[:payment_method][:id] == 'credit-card'
        unless current_user.stripe_customer_id
          customer = Stripe::Customer.create(email: current_user.email)
          current_user.update_attribute :stripe_customer_id, customer.id
        end
        customer = Stripe::Customer.retrieve current_user.stripe_customer_id unless customer
        card = customer.sources.create(card: params[:stripe_id])
        payment = current_user.payments.create({
                                                 stripe_id: card.id,
                                                 last4: card.last4,
                                                 card_type: card.brand.downcase.gsub(' ', '_'),
                                                 fingerprint: card.fingerprint,
                                                 status: :active
                                               })
      end
      payment.primary = true if first_payment

      if payment.save
        render json: { success: true, payment: payment }
      else
        render json: { success: false, message: payment.errors.full_messages[0] }
      end
    rescue Stripe::CardError => e
      body = e.json_body
      err  = body[:error]
      render json: { success: false, message: err[:message] }
    end
  end

  def delete
    # check if future booking exists with this payment
    future_bookings = payment.bookings.active
    if future_bookings.present?
      render json: { success: false, message: "There is at least one booking associated with this credit card" }
      return
    end

    if payment.primary
      render json: { success: false, message: "You can't delete your default payment" }
      return
    end

    customer = Stripe::Customer.retrieve(payment.user.stripe_customer_id)
    rsp = customer.sources.retrieve(payment.stripe_id).delete

    if rsp && rsp.deleted
      payment.update_attribute :status, :deleted
      payment.update_attribute :fingerprint, nil
      render json: { success: true }
    else
      render json: { success: false, message: "Error deleting credit card" }
    end
  end

  def default
    payment.primary = true
    payment.save

    # make other active payment methods as non-default
    current_user.payments.active.each do |p|
      next if p.id == payment.id
      p.update_attribute :primary, false
    end

    render nothing: true
  end
end
