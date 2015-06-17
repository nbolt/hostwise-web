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
    data = params[:data]
    jobs = Job.standard.complete
    total = jobs.count
    jobs = jobs.page(data['start'] / data['length'] + 1).per(data['length']) if data['length'] > 0
    filtered = jobs.count
    jobs = jobs.to_json(methods: [:soiled_twin_count, :soiled_king_count, :king_bed_count, :twin_bed_count, :contractor_names, :pillow_count, :bath_towel_count, :bath_mat_count, :hand_towel_count, :face_towel_count, :soiled_pillow_count, :soiled_bath_towel_count, :soiled_mat_count, :soiled_hand_count, :soiled_face_count], include: {booking: {methods: [:service_list], include: {property: {methods: [:nickname, :property_size, :neighborhood_address]}}}})
    render json: { jobs: jobs, total: total, filtered: filtered }
  end

end