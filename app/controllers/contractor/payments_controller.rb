class Contractor::PaymentsController < Contractor::AuthController
  def add
    begin
      recipient = Stripe::Account.retrieve current_user.contractor_profile.stripe_recipient_id

      if !params[:payment_method] || params[:payment_method][:id] == 'bank-account'
        recipient.bank_account = params[:stripe_id]
        recipient.save
        current_user.contractor_profile.verify_stripe! if recipient.verification.fields_needed[0]
        bank = recipient.bank_accounts.data[0]
        current_user.payments.destroy_all
        current_user.payments.create(bank_name: bank.bank_name, last4: bank.last4, routing_number: bank.routing_number, fingerprint: bank.fingerprint, stripe_id: bank.id, primary: true, status_cd: 1)
      end

      render json: { success: true }
    rescue Stripe::CardError => e
      body = e.json_body
      err  = body[:error]
      render json: { success: false, message: err[:message] }
    end
  end

  def remove
    current_user.payments.destroy_all
    render json: { success: true }
  end
end
