class Contractor::PaymentsController < Contractor::AuthController
  def add
    begin
      recipient = Stripe::Recipient.retrieve current_user.contractor_profile.stripe_recipient_id

      if !params[:payment_method] || params[:payment_method][:id] == 'bank-account'
        recipient.bank_account = params[:stripe_id]
        recipient.cards.retrieve(recipient.cards.data[0].id).delete() if recipient.cards.total_count > 0
      elsif params[:payment_method][:id] == 'credit-card'
        recipient.card = params[:stripe_id]
      end

      recipient.save
      render json: { success: true }
    rescue Stripe::CardError => e
      body = e.json_body
      err  = body[:error]
      render json: { success: false, message: err[:message] }
    end
  end
end
