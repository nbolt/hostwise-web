class Admin::DashboardController < Admin::AuthController
  include ActionView::Helpers::NumberHelper

  def revenue
    this_month = Job.revenue_on_month(Date.today)
    last_month = Job.revenue_on_month(Date.today - 1.month)
    total = Job.on_year(Date.today).standard.where('status_cd > 2').reduce(0) {|acc, job| acc + (job.chain(:booking, :prediscount_cost) || 0)}
    render json: { this_month: number_with_precision(this_month, precision: 2, delimiter: ','), last_month: number_with_precision(last_month, precision: 2, delimiter: ','), total: number_with_precision(total, precision: 2, delimiter: ',') }
  end

  def payouts
    this_month = Job.payouts_on_month(Date.today)
    last_month = Job.payouts_on_month(Date.today - 1.month)
    total = Job.standard.where('status_cd > 2').reduce(0) {|acc, job| acc + job.payouts.reduce(0) {|a,p| a + (p.amount || 0)}} / 100.0
    render json: { data: data, total: number_with_precision(total, precision: 2, delimiter: ',') }
  end

  def serviced
    this_month = Job.serviced_on_month(Date.today)
    last_month = Job.serviced_on_month(Date.today - 1.month)
    total = Job.on_year(Date.today).standard.complete.count
    render json: { this_month: number_with_delimiter(this_month), last_month: number_with_delimiter(last_month), total: number_with_delimiter(total) }
  end

  def properties
    this_month  = Job.properties_on_month(Date.today)
    last_month  = Job.properties_on_month(Date.today - 1.month)
    total = Job.on_year(Date.today).standard.complete.select('distinct bookings.property_id').includes(:booking).references(:bookings).count
    render json: { this_month: number_with_delimiter(this_month), last_month: number_with_delimiter(last_month), total: number_with_delimiter(total) }
  end

  def hosts
    this_month = Job.hosts_on_month(Date.today)
    last_month = Job.hosts_on_month(Date.today - 1.month)
    total = Job.on_year(Date.today).standard.complete.select('distinct properties.user_id').includes(booking: [:property]).references(:properties).count
    render json: { this_month: number_with_delimiter(this_month), last_month: number_with_delimiter(last_month), total: number_with_delimiter(total) }
  end

end
