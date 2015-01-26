class Contractor::JobsController < Contractor::AuthController

  expose(:job) { Job.find params[:id] }

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
