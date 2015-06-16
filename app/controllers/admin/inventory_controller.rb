class Admin::InventoryController < Admin::AuthController
  expose(:job) { Job.find params[:id] }

  def index
    @distro = Job.distribution
    @distro = @distro.group_by(&:date)
    @distro.each{|date, jobs| @distro[date] = jobs.group_by{|job| job.distribution_center.then(:id)}} 

    respond_to do |format|
      format.html
    end
  end

  def export
    @inventory = params[:inventory]
    @distro = Job.distribution.order(:date)
    @distro = @distro.group_by(&:date)
    @distro.each{|date, jobs| @distro[date] = jobs.group_by{|job| job.distribution_center.then(:id)}} 

    
    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"bookings.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  def jobs
    render json: Job.standard.complete.to_json(methods: [:soiled_twin_count, :soiled_king_count, :king_bed_count, :twin_bed_count, :contractor_names], include: {booking: {methods: [:service_list], include: {property: {methods: [:nickname, :property_size, :neighborhood_address]}}}})
  end

end