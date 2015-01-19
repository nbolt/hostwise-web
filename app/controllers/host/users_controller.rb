class Host::UsersController < Host::AuthController
  def edit
    respond_to do |format|
      format.html
      format.json { render json: current_user.to_json(methods: [:avatar, :name]) }
    end
  end

  def update
    user = current_user
    if params[:step] == 'info'
      user.step = 'edit_info'
      user.assign_attributes(user_params)
    elsif params[:step] == 'password'
      user.step = 'edit_password'
      unless params[:form][:current_password].present?
        render json: { success: false, message: 'Current password is required' }
        return
      end
      unless User.authenticate(user.email, params[:form][:current_password]).present?
        render json: { success: false, message: "Current password doesn't match" }
        return
      end
      params[:form].delete :current_password #clear unpermitted param
      user.assign_attributes(user_params)
    elsif params[:step] == 'photo'
      user.avatars.build(photo: params[:file]) # need to background this
    end

    if user.save
      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def add_payment
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

  def message
    message = current_user.messages.create({body: params[:form][:message]})

    if message.save
      #TODO: forward the message to support@useporter.com
      render json: { success: true }
    else
      render json: { success: false, message: message.errors.full_messages[0] }
    end
  end

  private

  def user_params
    params.require(:form).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone_number)
  end
end