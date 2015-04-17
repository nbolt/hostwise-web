class Admin::InventoryController < Admin::AuthController
  expose(:job) { Job.find params[:id] }

  def index
    @days = []
    distribution_jobs = Job.distribution
    @days = distribution_jobs.group_by(&:date)
    @days.to_a.reverse!

    @days.each do |day|
      day = day[1].group_by(&:distribution_center)
      day.to_a.reverse!
    end

    @days = @days.to_h

    jobs = Job.distribution
    case params[:filter]
    when 'complete'
      jobs = jobs.where(status_cd: [3,5,6])
    when 'active'
      jobs = jobs.where(status_cd: [0,1])
    when 'future'
      jobs = jobs.future_from_today 'America/Los_Angeles'
    end
    jobs = jobs.search(params[:search]) if params[:search] && !params[:search].empty?

    respond_to do |format|
      format.html
      format.json do
        render json: jobs.includes(contractors: {}, booking: {property: {user: {}}})
      end
    end
  end
end