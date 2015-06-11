class Admin::HostsController < Admin::AuthController
  expose(:contractor) { User.find_by_id params[:id] }

  def index
    respond_to do |format|
      format.html
      format.json { render json: User.hosts, each_serializer: HostSerializer, root: :hosts }
      #format.json { render json: User.hosts.to_json(include: {properties: {include: {bookings: {}, active_bookings: {}, past_bookings: {include: {successful_transactions: {}}}}, methods: [:future_bookings]}}, methods: [:name, :avatar, :next_service_date, :display_phone_number, :total_spent]) }
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: User.find_by_id(params[:id]).to_json(include: {properties: {methods: [:last_service_date, :next_service_date, :revenue, :nickname, :display_created_at], include: {bookings: {methods: [:cost, :formatted_date]}}}}, methods: [:name, :avatar, :total_spent]) }
      #format.json { render json: User.find(params[:id]), serializer: HostSerializer }
    end
  end

  def transfer
    amount = (params[:amount].to_f * 100).to_i
    recipient = Stripe::Account.retrieve contractor.contractor_profile.stripe_recipient_id
    rsp = Stripe::Transfer.create(
      :amount => amount,
      :currency => 'usd',
      :destination => recipient.id,
      :statement_descriptor => 'HostWise Payout',
      :metadata => { reason: params[:reason] }
    )
    contractor.payouts.create(status_cd: 2, amount: amount, stripe_transfer_id: rsp.id, payout_type_cd: 1)
    render json: { success: true }
  end

  def notes
    @host = User.find(params[:id])
  end

  def new_note
    host_id = params[:id]
    comment = params[:comment]
    user_id = current_user.id
    User.find(host_id).comments.create(comment: comment, user_id: user_id)
    redirect_to "/hosts/#{host_id}/notes"
  end

  def update
    user = User.find_by_id params[:id]
    user.assign_attributes host_params
    user.step = 'edit_info'

    if user.valid?
      user.save
      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def deactivate
    User.find_by_id(params[:id]).deactivate!
    render json: { success: true }
  end

  def reactivate
    User.find_by_id(params[:id]).reactivate!
    render json: { success: true }
  end

  private

  def host_params
    params.require(:host).permit(:email, :first_name, :last_name, :phone_number)
  end
end
