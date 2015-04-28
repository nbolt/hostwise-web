class Admin::DashboardController < Admin::AuthController
  include ActionView::Helpers::NumberHelper

  def revenue
    data = Job.revenue_by_months(Date.today)
    render json: { data: data, average: number_with_delimiter(data.reduce(0) {|acc, r| acc + r[:revenue]} / data.count) }
  end

  def serviced
    data = Job.serviced_by_months(Date.today)
    render json: { data: data, average: number_with_delimiter(data.reduce(0) {|acc, r| acc + r[:serviced]} / data.count) }
  end

  def properties
    data = Job.properties_by_months(Date.today)
    render json: { data: data, average: number_with_delimiter(data.reduce(0) {|acc, r| acc + r[:properties]} / data.count) }
  end

  def hosts
    data = Job.hosts_by_months(Date.today)
    render json: { data: data, average: number_with_delimiter(data.reduce(0) {|acc, r| acc + r[:hosts]} / data.count) }
  end

end
