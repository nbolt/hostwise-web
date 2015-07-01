class Admin::HostsController < Admin::AuthController
  include CsvHelper
  expose(:host) { User.find_by_id params[:id] }

  def index
    hosts = User.hosts
    hosts = hosts.within_market(current_user.market) if current_user.market
    respond_to do |format|
      format.html
      format.json { render json: hosts, each_serializer: HostSerializer, root: :hosts }
      #format.json { render json: User.hosts.to_json(include: {properties: {include: {bookings: {}, active_bookings: {}, past_bookings: {include: {successful_transactions: {}}}}, methods: [:future_bookings]}}, methods: [:name, :avatar, :next_service_date, :display_phone_number, :total_spent]) }
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: User.find_by_id(params[:id]).to_json(include: {properties: {methods: [:last_service_date, :next_service_date, :revenue, :nickname, :display_created_at], include: {bookings: {methods: [:cost, :formatted_date]}}}}, methods: [:name, :avatar, :total_spent, :default_payment]) }
      #format.json { render json: User.find(params[:id]), serializer: HostSerializer }
    end
  end

  def export
    hosts = User.hosts
    hosts = hosts.within_market(current_user.market) if current_user.market
    respond_to do |format|
      format.csv { send_data host_csv(hosts), filename: 'hosts.csv' }
    end
  end

  def charge
    begin
      amount = (params[:amount].to_f * 100).to_i
      rsp = Stripe::Charge.create(
        amount: amount,
        currency: 'usd',
        customer: host.stripe_customer_id,
        source: host.payments.primary[0].stripe_id,
        statement_descriptor: "HostWise"[0..21], # 22 characters max
        metadata: { reason: params[:reason] }
      )
      transaction = Transaction.create(stripe_charge_id: rsp.id, status_cd: 0, amount: amount, transaction_type_cd: 1)
      # UserMailer.service_completed(booking).then(:deliver) if user_bookings[:user].settings(:service_completion).email
      render json: { success: true }
    rescue Stripe::CardError => e
      err  = e.json_body[:error]
      transaction = Transaction.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message], transaction_type_cd: 1)
      render json: { success: false }
    end
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
