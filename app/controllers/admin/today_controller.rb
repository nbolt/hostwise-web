class Admin::TodayController < Admin::AuthController
  include CsvHelper
  expose(:job) { Job.find params[:id] }

  def index
    data = if params[:data] then JSON.parse params[:data] else nil end
    filtered_jobs = nil
    if params[:date].present?
      date = Time.strptime(params[:date], '%m/%d/%Y')
      jobs = Job.standard.on_date(date).includes(booking: {property: {zip_code: {market: {}}}, user: {}})
    else
      jobs = Job.standard.today.includes(booking: {property: {zip_code: {market: {}}}, user: {}})
    end
    jobs = jobs.within_market(current_user.market) if current_user.market
    jobs = jobs.search(params[:search]) if params[:search] && !params[:search].empty?
    total = jobs.count

    if data
      jobs = jobs.search(data['search']['value']).to_a if data['search']['value'].present?
      filtered_jobs = jobs
      jobs = Kaminari.paginate_array(jobs).page(data['start'] / data['length'] + 1).per(data['length']) if data['length'] > 0
    end

    respond_to do |format|
      format.html
      format.json do
        render json: jobs, root: :jobs, meta: { total: total, filtered: filtered_jobs.then(:count) }
      end
    end
  end

end
