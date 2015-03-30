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
    zip = Zip.serviced.where(code: params[:zip]).first
    UnservicedZip.create(code: params[:zip], email: current_user.email) unless zip
    render json: zip
  end

  def payments
    render json: current_user.payments
  end

  def jobs
    jobs = Job.all
    case params[:scope]
      when 'open'
        jobs = jobs.future(current_user.contractor_profile.zone).open(current_user)
      when 'upcoming'
        jobs = jobs.upcoming(current_user)
      when 'past'
        jobs = jobs.past(current_user)
    end
    jobs.each {|j| j.current_user = current_user}
    jobs.select {|job| !job.previous_team_job && (job.first_job_of_day || job.contractor_hours + job.man_hours <= MAX_MAN_HOURS)} if params[:scope] == 'open'
    jobs_count = jobs.count
    jobs = jobs.group_by{|job| job.date.strftime '%m-%d-%y'}.sort_by{|date| Date.strptime(date[0], '%m-%d-%y')}
    if params[:scope] == 'open'
      jobs = jobs.group_by{|jobs| day = Date.strptime(jobs[0], '%m-%d-%y'); (day - day.wday).strftime('%m-%d-%y')}.sort_by{|jobs |Date.strptime(jobs[0], '%m-%d-%y')}
      render json: { weeks_count: jobs.count, jobs_count: jobs_count, jobs: jobs[params[:page].to_i][1].to_json(methods: [:payout, :payout_integer, :payout_fractional, :staging, :man_hours, :contractor_hours, :first_job_of_day, :previous_team_job], include: {contractors: {}, booking: {methods: :cost, include: {property: {include: {user: {methods: :name}}, methods: [:short_address, :full_address, :primary_photo, :neighborhood]}}}}) }
    else
      render json: jobs.to_json(methods: [:payout, :payout_integer, :payout_fractional, :staging, :man_hours, :contractor_hours, :first_job_of_day, :previous_team_job], include: {contractors: {}, booking: {methods: :cost, include: {property: {include: {user: {methods: :name}}, methods: [:short_address, :full_address, :primary_photo, :neighborhood]}}}})
    end
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
