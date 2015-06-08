class Api::UsersController < ApplicationController

  before_filter :authenticate

  expose(:user) do
    user = User.find params[:id]
    user if user.auth_token == params[:token]
  end

  def show
    timezone = Timezone::Zone.new :zone => user.contractor_profile.zone
    jobs = user.jobs.on_date(timezone.time Time.now).ordered(user)
    jobs.each {|j| j.current_user = user}
    render json: [Job.pickup.last, Job.standard.last].to_json(methods: [:payout_integer, :payout_fractional, :staging, :formatted_time], include: {distribution_center: {methods: [:full_address]}, contractors: {}, booking: {include: {property: {include: [user: {methods: [:name]}], methods: [:full_address]}}}})
  end

  private

  def authenticate
    unless user
      render json: { success: false }, status: :unauthorized
      return
    end
  end

end
