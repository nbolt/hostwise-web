class Admin::HostsController < Admin::AuthController
  def index
    respond_to do |format|
      format.html
      format.json { render json: User.hosts.to_json(include: {properties: {include: {bookings: {}, active_bookings: {}, past_bookings: {include: {successful_transactions: {}}}}}}, methods: [:name, :avatar, :next_service_date, :display_phone_number]) }
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: User.find_by_id(params[:id]).to_json(include: {properties: {methods: [:last_service_date, :next_service_date], include: {bookings: {methods: [:cost, :formatted_date]}}}}, methods: [:name, :avatar]) } 
      #format.json { render json: User.find(params[:id]), serializer: HostSerializer }
    end
  end

  def notes
    host_id = params[:id]
    @comments = User.find(host_id).comments
    @users = User.all

    respond_to do |format|
      format.html
      format.json { render json: User.find_by_id(params[:id]).to_json(include: {comments: {methods:[]}, properties: {methods: [:last_service_date, :next_service_date], include: {bookings: {methods: [:cost, :formatted_date]}}}}, methods: [:name, :avatar]) } 
      #format.json { render json: User.find(params[:id]), serializer: HostSerializer }
    end
  end

  def new_note
    host_id = params[:id]
    title = params[:title]
    comment = params[:comment]
    user_id = current_user.id
    User.find(host_id).comments.create(title: title, comment: comment, user_id: user_id)
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
