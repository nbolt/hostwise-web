class Admin::DashboardController < Admin::AuthController
  include ActionView::Helpers::NumberHelper

  def revenue
    data = Job.revenue_by_weeks(Date.today)
    render json: { data: data, num_weeks: data.count, total: number_with_delimiter(data.reduce(0) {|acc, week| acc + week}) }
  end

  def serviced
    data = Job.serviced_by_weeks(Date.today)
    render json: { data: data, num_weeks: data.count, total: number_with_delimiter(data.reduce(0) {|acc, week| acc + week}) }
  end

  def properties
    data = Job.properties_by_weeks(Date.today)
    render json: { data: data, num_weeks: data.count, total: number_with_delimiter(data.reduce(0) {|acc, week| acc + week}) }
  end

  def hosts
    data = Job.hosts_by_weeks(Date.today)
    render json: { data: data, num_weeks: data.count, total: number_with_delimiter(data.reduce(0) {|acc, week| acc + week}) }
  end

end
