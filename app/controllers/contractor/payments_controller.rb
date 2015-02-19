class Contractor::PaymentsController < Contractor::AuthController
  def add
    bank_account = Balanced::BankAccount.fetch "/bank_accounts/#{params[:balanced_id]}"
    bank_account.associate_to_customer "/customers/#{current_user.balanced_customer_id}"
    verification = bank_account.verify
    payment = current_user.payments.create({
                                             balanced_id: bank_account.id,
                                             last4: bank_account.account_number.gsub('x',''),
                                             fingerprint: bank_account.fingerprint,
                                             balanced_verification_id: verification.id,
                                             bank_name: bank_account.bank_name,
                                             holder_name: bank_account.name,
                                             routing_number: bank_account.routing_number,
                                             status: :active
                                           })
    if payment.save
      render json: { success: true }
    else
      render json: { success: false, message: payment.errors.full_messages[0] }
    end
  end

  def delete
    payment = Payment.find_by_id(params[:payment_id])
    bank_account = Balanced::BankAccount.fetch "/bank_accounts/#{payment.balanced_id}"
    rsp = bank_account.destroy

    if rsp && rsp.status == 204
      payment.update_attribute :status, :deleted
      payment.update_attribute :fingerprint, nil
      render json: { success: true }
    else
      render json: { success: false, message: 'Error deleting bank account' }
    end
  end
end
