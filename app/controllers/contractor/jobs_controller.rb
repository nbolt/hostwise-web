class Contractor::JobsController < Contractor::AuthController

  expose(:job) { Job.find params[:id] }

  def show
    respond_to do |format|
      format.html
      format.json { render json: job.to_json(include: [booking: {methods: [:cost], include: [property: {include: {user: {methods: [:avatar, :display_phone_number, :name]}}, methods: [:primary_photo, :full_address]}]}]) }
    end
  end

  def claim
    if current_user.claim_job job
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def drop
    if current_user.drop_job job
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

end
