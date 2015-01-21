class Host::PaymentsController < Host::AuthController
  def add
    if params[:payment_method][:id] == 'credit-card'
      customer = Stripe::Customer.retrieve current_user.stripe_customer_id
      card = customer.cards.create(card: params[:stripe_id])
      payment = current_user.payments.create({
                                               stripe_id: card.id,
                                               last4: card.last4,
                                               card_type: card.brand.downcase.gsub(' ', '_'),
                                               fingerprint: card.fingerprint
                                             })
    else
      bank_account = Balanced::BankAccount.fetch "/bank_accounts/#{params[:balanced_id]}"
      bank_account.associate_to_customer "/customers/#{current_user.balanced_customer_id}"
      payment = current_user.payments.create({
                                               balanced_id: bank_account.id,
                                               last4: bank_account.account_number.gsub('x',''),
                                               fingerprint: bank_account.fingerprint
                                             })
    end
    if payment.save
      render json: { success: true, payment: payment }
    else
      render json: { success: false, message: payment.errors.full_messages[0] }
    end
  end

  def delete
    payment = Payment.find_by_id(params[:payment_id])

    # check if future booking exists with this payment
    future_bookings = payment.bookings.select { |booking| booking.date > Date.today }
    if future_bookings.present?
      render json: { success: false, message: "There is at least one booking associated with this #{payment.card? ? 'credit card' : 'bank account'}" }
      return
    end

    if payment.card?
      customer = Stripe::Customer.retrieve(payment.user.stripe_customer_id)
      rsp = customer.cards.retrieve(payment.stripe_id).delete
    elsif payment.bank?
      bank_account = Balanced::BankAccount.fetch "/bank_accounts/#{payment.balanced_id}"
      rsp = bank_account.destroy
    end

    if rsp && (payment.card? ? rsp.deleted : rsp.status == 204)
      payment.update_attribute :status, :deleted
      payment.update_attribute :fingerprint, nil
      render json: { success: true }
    else
      render json: { success: false, message: "Error deleting #{payment.card? ? 'credit card' : 'bank account'}" }
    end
  end
end
