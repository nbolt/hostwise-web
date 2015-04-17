class Admin::InventoryController < Admin::AuthController
  expose(:job) { Job.find params[:id] }

  def index
    @distro = Job.distribution
    @distro = @distro.group_by(&:date)
    @distro.each{|date, jobs| @distro[date] = jobs.group_by{|job| job.distribution_center.id}} 

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