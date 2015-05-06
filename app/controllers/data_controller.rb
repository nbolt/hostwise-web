class DataController < ApplicationController
  include CsvHelper

  def cities
    render json: City.search(params[:term]).to_json(methods: :state, include: :county)
  end

  def services
    render json: Service.all
  end

  def properties
    render json: Property.by_user(current_user).search(params[:term], params[:sort]).to_json(include: {property_photos: {}, bookings: {include: [:job]}}, methods: [:primary_photo, :nickname, :short_address, :full_address, :next_service_date])
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
        if !job.previous_team_job && !job.training && (job.first_job_of_day(current_user) || job.contractor_hours(current_user) + job.man_hours <= MAX_MAN_HOURS)
          processed += 1
          selected_jobs.push job if processed > offset && processed <= offset + JOBS_PER_PAGE
        end
        num += 1
      end
      selected_jobs.each {|j| j.current_user = current_user}
      jobs = selected_jobs.group_by{|job| job.date.strftime '%m-%d-%y'}.sort_by{|date| Date.strptime(date[0], '%m-%d-%y')}
      render json: { jobs_count: processed, jobs: jobs.to_json(methods: [:payout, :payout_integer, :payout_fractional, :staging, :man_hours, :contractor_hours], include: {contractors: {}, booking: {methods: :cost, include: {property: {include: {user: {methods: :name}}, methods: [:short_address, :full_address, :primary_photo, :neighborhood]}}}}) }
    else
      jobs.each {|j| j.current_user = current_user}
      jobs = jobs.group_by{|job| job.date.strftime '%m-%d-%y'}.sort_by{|date| Date.strptime(date[0], '%m-%d-%y')}
      jobs = jobs.each {|jobs| jobs[1] = jobs[1].sort_by{|job| job.priority}} if params[:scope] == 'upcoming'
      render json: jobs.to_json(methods: [:payout, :payout_integer, :payout_fractional, :staging, :man_hours, :contractor_hours], include: {contractors: {}, booking: {methods: :cost, include: {property: {include: {user: {methods: :name}}, methods: [:short_address, :full_address, :primary_photo, :neighborhood]}}}})
    end
  end

  def refresh_day
    job = Job.find params[:id]
    jobs = Job.on_date(job.date).open current_user
    jobs.each {|j| j.current_user = current_user}
    jobs = jobs.select {|job| !job.previous_team_job && !job.training && (job.first_job_of_day || job.contractor_hours + job.man_hours <= MAX_MAN_HOURS)}
    render json: jobs.to_json(methods: [:payout, :payout_integer, :payout_fractional, :staging, :man_hours, :contractor_hours], include: {contractors: {}, booking: {methods: :cost, include: {property: {include: {user: {methods: :name}}, methods: [:short_address, :full_address, :primary_photo, :neighborhood]}}}})
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
