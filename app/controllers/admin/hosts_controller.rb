class Admin::HostsController < Admin::AuthController
  def index
    respond_to do |format|
      format.html
      format.json { render json: User.hosts.to_json(include: [:properties], methods: [:name, :avatar, :next_service_date]) }
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: User.find_by_id(params[:id]).to_json(methods: [:name, :avatar]) }
    end
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