class Admin::DashboardController < Admin::AuthController
  include ActionView::Helpers::NumberHelper

  def revenue
    data  = Job.revenue_by_months(Date.today)
    total = Job.standard.where('status_cd > 2').reduce(0) {|acc, job| acc + (job.chain(:booking, :cost) || 0)}
    render json: { data: data, total: number_with_precision(total, precision: 2, delimiter: ',') }
  end

  def payouts
    data  = Job.payouts_by_months(Date.today)
    total = Job.standard.where('status_cd > 2').reduce(0) {|acc, job| acc + job.payouts.reduce(0) {|a,p| a + (p.amount || 0)}} / 100.0
    render json: { data: data, total: number_with_precision(total, precision: 2, delimiter: ',') }
  end

  def serviced
    data  = Job.serviced_by_months(Date.today)
    total = Job.standard.complete.count
    render json: { data: data, total: number_with_delimiter(total) }
  end

  def properties
    data  = Job.properties_by_months(Date.today)
    total = Job.standard.complete.select('distinct bookings.property_id').includes(:booking).references(:bookings).count
    render json: { data: data, total: number_with_delimiter(total) }
  end

  def hosts
    data  = Job.hosts_by_months(Date.today)
    total = Job.standard.complete.select('distinct properties.user_id').includes(booking: [:property]).references(:properties).count
    render json: { data: data, total: number_with_delimiter(total) }
  end

end
