class Contractor::PaymentsController < Contractor::AuthController
  def add
    bank_account = Balanced::BankAccount.fetch "/bank_accounts/#{params[:balanced_id]}"
    bank_account.associate_to_customer "/customers/#{current_user.balanced_customer_id}"
    payment = current_user.payments.create({
                                             balanced_id: bank_account.id,
                                             last4: bank_account.account_number.gsub('x',''),
                                             fingerprint: bank_account.fingerprint
                                           })
    if payment.save
      render json: { success: true }
    else
      render json: { success: false, message: payment.errors.full_messages[0] }
    end
  end
end
