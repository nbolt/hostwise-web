class DataController < ApplicationController
  include CsvHelper

  def coupon_users
    render json: User.hosts(params[:term])
  end

  def cities
    render json: City.search(params[:term]).to_json(methods: :state, include: :county)
  end

  def services
    render json: Service.all
  end

  def properties
    render json: Property.by_user(current_user).search(params[:term], params[:sort]), each_serializer: UserPropertySerializer, root: :properties
  end

  def markets
    render json: Market.all, root: :markets
  end

  def timeslots
    render json: { timeslots: PRICING['timeslots'] }
  end

  def service_available
    zip = ZipCode.serviced.where(code: params[:zip]).first
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
    if params[:scope] == 'open'
      selected_jobs = []; num = 0; processed = 0; offset = (params[:page].to_i - 1) * JOBS_PER_PAGE
      while selected_jobs.count < JOBS_PER_PAGE && jobs[num]
        job = jobs[num]
        if current_user.can_claim_job?(job)[:success]
          processed += 1
          selected_jobs.push job if processed > offset && processed <= offset + JOBS_PER_PAGE
        end
        num += 1
      end
      selected_jobs.each {|j| j.current_user = current_user}
      render json: selected_jobs, each_serializer: DataJobsSerializer, meta: { jobs_count: processed }, root: :jobs
    else
      jobs.each {|j| j.current_user = current_user}
      render json: jobs, each_serializer: DataJobsSerializer, root: :jobs
    end
  end

  def refresh_day
    job = Job.find params[:id]
    jobs = Job.on_date(job.date).open current_user
    jobs.each {|j| j.current_user = current_user}
    jobs = jobs.select {|job| current_user.can_claim_job?(job)[:success]}
    render json: jobs.to_json(methods: [:payout, :payout_integer, :payout_fractional, :staging, :man_hours, :contractor_hours, :formatted_time], include: {contractors: {}, booking: {methods: :cost, include: {property: {include: {user: {methods: :name}}, methods: [:short_address, :full_address, :primary_photo, :neighborhood]}}}})
  end

  def transactions
    case params[:scope]
      when 'completed'
        transactions = Transaction.completed(current_user, params[:start_date], params[:end_date])
        respond_to do |format|
          format.json { render json: transactions.to_json(include: {bookings: {methods: :cost, include: [:payment, :services, :user, property: {methods: :nickname}]}}) }
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
