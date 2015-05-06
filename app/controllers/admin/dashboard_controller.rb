class Admin::DashboardController < Admin::AuthController
  include ActionView::Helpers::NumberHelper

  def revenue
    this_month = Job.revenue_on_month(Date.today)
    last_month = Job.revenue_on_month(Date.today - 1.month)
    last_month2 = Job.revenue_on_month(Date.today - 2.months)
    if this_month > 0 && last_month > 0
      growth = ((last_month - last_month2) / last_month2 * 100).round 2
    else
      growth = 0
    end
    total = Job.on_year(Date.today).standard.where('status_cd > 2').reduce(0) {|acc, job| acc + (job.chain(:booking, :prediscount_cost) || 0)}
    render json: { this_month: number_with_precision(this_month, precision: 2, delimiter: ','), last_month: number_with_precision(last_month, precision: 2, delimiter: ','), total: number_with_precision(total, precision: 2, delimiter: ','), growth: growth }
  end

  def payouts
    this_month = Job.payouts_on_month(Date.today)
    # last_month = Job.payouts_on_month(Date.today - 1.month)
    pending = 0
    User.all.each {|user| user.payouts.unprocessed.each {|payout| pending += payout.total} if user.chain(:contractor_profile, :stripe_recipient_id)}
    total = Job.standard.where('status_cd > 2').reduce(0) {|acc, job| acc + job.payouts.reduce(0) {|a,p| a + (p.amount || 0)}} / 100.0
    render json: { this_month: number_with_precision(this_month, precision: 2, delimiter: ','), total: number_with_precision(total, precision: 2, delimiter: ','), pending: number_with_precision(pending, precision: 2, delimiter: ',') }
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
