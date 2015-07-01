class Admin::InventoryController < Admin::AuthController
  include CsvHelper
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

  def export_properties
    properties = Property.all
    properties = properties.within_market(current_user.market) if current_user.market
    respond_to do |format|
      format.csv { send_data inventory_properties_csv(properties), filename: 'inventory_properties.csv' }
    end
  end

  def export_jobs
    jobs = Job.standard.complete
    jobs = jobs.within_market(current_user.market) if current_user.market
    respond_to do |format|
      format.csv { send_data inventory_jobs_csv(jobs), filename: 'inventory_jobs.csv' }
    end
  end

  def jobs
    data = params[:data]
    jobs = Job.standard.complete
    jobs = jobs.within_market(current_user.market) if current_user.market
    total = jobs.count
    jobs = jobs.search(data['search']['value']) if data['search']['value'].present?
    filtered = jobs.count
    jobs = Kaminari.paginate_array(jobs.to_a).page(data['start'] / data['length'] + 1).per(data['length']) if data['length'] > 0
    jobs = jobs.to_json(methods: [:soiled_twin_count, :soiled_king_count, :king_bed_count, :twin_bed_count, :contractor_names, :pillow_count, :bath_towel_count, :bath_mat_count, :hand_towel_count, :face_towel_count, :soiled_pillow_count, :soiled_bath_towel_count, :soiled_mat_count, :soiled_hand_count, :soiled_face_count], include: {booking: {methods: [:service_list], include: {property: {methods: [:nickname, :property_size, :neighborhood_address]}}}})
    render json: { jobs: jobs, total: total, filtered: filtered }
  end

end