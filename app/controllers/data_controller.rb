class DataController < ApplicationController
  include CsvHelper

  def cities
    render json: City.search(params[:term]).to_json(methods: :state, include: :county)
  end

  def services
    render json: Service.all
  end

  def properties
    render json: Property.by_user(current_user).search(params[:term], params[:sort]).to_json(include: [:property_photos], methods: [:primary_photo, :nickname, :short_address, :full_address, :next_service_date])
  end

  def service_available
    render json: Zip.serviced.where(code: params[:zip]).first
  end

  def payments
    render json: current_user.payments
  end

  def jobs
    jobs = Job.all
    case params[:scope]
      when 'open'
        jobs = jobs.open(current_user)
      when 'upcoming'
        jobs = jobs.upcoming(current_user)
      when 'past'
        jobs = jobs.past(current_user)
    end
    jobs = jobs.group_by{|job| job.date.strftime '%m-%d-%y'}.sort_by{|d|d}
    render json: jobs.to_json(methods: [:payout_integer, :payout_fractional], include: {contractors: {}, booking: {methods: :cost, include: {property: {include: {user: {methods: :name}}, methods: [:short_address, :primary_photo, :neighborhood]}}}})
  end

  def transactions
    case params[:scope]
      when 'completed'
        transactions = Transaction.completed(current_user, params[:start_date], params[:end_date])
        respond_to do |format|
          format.json { render json: transactions.to_json(include: {booking: {methods: :cost, include: [:payment, :services, property: {methods: :nickname}]}}) }
          format.csv { send_data transaction_csv(transactions), filename: "completed_transactions_#{params[:start_date].gsub('/', '_')}_#{params[:end_date].gsub('/', '_')}.csv" }
        end
      when 'upcoming'
        bookings = Booking.upcoming current_user
        respond_to do |format|
          format.json { render json: bookings.to_json(methods: :cost, include: [:payment, :services, property: {methods: :nickname}]) }
        end
    end
  end

  def contractors
    render json: User.contractors(params[:term]).to_json(include: [contractor_profile: {methods: [:position]}], methods: [:avatar, :name, :role])
  end

  def hosts
    render json: User.hosts(params[:term]).to_json(include: [:properties], methods: [:name, :avatar, :role, :next_service_date])
  end
end
