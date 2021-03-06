class Admin::JobsController < Admin::AuthController
  include CsvHelper
  expose(:job) { Job.find params[:id] }

  def index
    data = if params[:data] then JSON.parse params[:data] else nil end
    filtered_jobs = nil
    jobs = Job.standard.includes(booking: {property: {zip_code: {market: {}}}, user: {}})
    jobs = jobs.within_market(current_user.market) if current_user.market
    case params[:filter]
    when 'complete'
      jobs = jobs.where(status_cd: [3,5,6]).where('bookings.status_cd != 0').includes(:booking).references(:bookings)
    when 'active'
      jobs = jobs.where(status_cd: [0,1])
    when 'future'
      jobs = jobs.future_from_today 'America/Los_Angeles'
    end
    jobs = jobs.search(params[:search]) if params[:search] && !params[:search].empty?
    total = jobs.count

    if data
      jobs = jobs.search(data['search']['value']).to_a if data['search']['value'].present?
      if params[:dash] == 'jobs'
        data['columns'].each do |column|
          value = column['search']['value'].then(:downcase)
          if value.present?
            jobs =
              case column['data']
              when 0 then jobs.select {|job| job.id.to_s.match value}
              when 1 then jobs.select {|job| job.booking.property.id.to_s.match value}
              when 2 then jobs.select {|job| "#{job.booking.timeslot_type_cd == 0 && 'Flex' || 'Specific'} - #{job.formatted_time}".match value}
              when 3 then jobs.select {|job| job.booking.property.zip_code.market.name.downcase.match value}
              when 4 then jobs.select {|job| job.booking.property.property_size.downcase.match value}
              when 5 then jobs.select {|job| job.booking.linen_handling.to_s.match value}
              when 7 then jobs.select {|job| job.booking.property.nickname.downcase.match value}
              when 8 then jobs.select {|job| job.booking.property.neighborhood_address.downcase.match value}
              when 9 then jobs.select {|job| job.booking.user.name.downcase.match value}
              when 10 then jobs.select {|job| job.booking.user.phone_number.match value}
              when 11 then jobs.select {|job| job.status.to_s.match value}
              when 12 then jobs.select {|job| job.contractor_names.downcase.match value}
              when 13 then jobs.select {|job| "$#{job.booking.cost}".match value}
              when 14 then jobs.select {|job| job.booking.service_list.downcase.match value}
              when 21 then jobs.select {|job| job.state.to_s.downcase.match value}
              when 6 then jobs.select do |job|
                from = value.split('|')[0]
                to   = value.split('|')[1]
                if from.then(:present?) && to.then(:present?)
                  job.date >= Date.strptime(from, '%m/%d/%Y') && job.date <= Date.strptime(to, '%m/%d/%Y')
                else
                  true
                end
              end
              end
          end
        end
        data['order'].each do |order|
          dir = if order['dir'] == 'asc' then 1 else -1 end
          jobs =
            case order['column']
            when 0 then jobs.sort_by {|job| dir * job.id}
            when 1 then jobs.sort_by {|job| dir * job.booking.property.id}
            when 2 then dir == 1 && jobs.sort_by {|job| job.formatted_time} || jobs.sort_by {|job| job.formatted_time}.reverse
            when 6 then jobs.sort_by {|job| dir * job.date.to_time.to_i}
            when 9 then dir == 1 && jobs.sort_by {|job| job.booking.user.name} || jobs.sort_by {|job| job.booking.user.name}.reverse
            when 11 then jobs.sort_by {|job| dir * job.status_cd}
            when 12 then dir == 1 && jobs.sort_by {|job| job.contractor_names} || jobs.sort_by {|job| job.contractor_names}.reverse
            when 14 then dir == 1 && jobs.sort_by {|job| job.booking.service_list} || jobs.sort_by {|job| job.booking.service_list}.reverse
            end
        end
      else
        data['columns'].each do |column|
          value = column['search']['value'].then(:downcase)
          if value.present?
            jobs =
              case column['data']
              when 0 then jobs
              when 1 then jobs.select {|job| job.id.to_s.match value}
              when 2 then jobs.select {|job| job.booking.property.id.to_s.match value}
              when 3 then jobs.select {|job| job.booking.user.id.to_s.match value}
              when 5 then jobs.select {|job| job.booking.user.name.downcase.match value}
              when 6 then jobs.select {|job| job.contractor_names.downcase.match value}
              when 7 then jobs.select {|job| job.status.to_s.match value}
              when 8 then jobs # adjusted payout
              when 9 then jobs # total payout
              when 4 then jobs.select do |job|
                from = value.split('|')[0]
                to   = value.split('|')[1]
                if from && to
                  job.date >= Date.strptime(from, '%m/%d/%Y') && job.date <= Date.strptime(to, '%m/%d/%Y')
                else
                  true
                end
              end
              end
          end
        end
        data['order'].each do |order|
          dir = if order['dir'] == 'asc' then 1 else -1 end
          jobs =
            case order['column']
            when 0 then jobs
            when 1 then jobs.sort_by {|job| dir * job.id}
            when 2 then jobs.sort_by {|job| dir * job.booking.property.id}
            when 3 then jobs.sort_by {|job| dir * job.booking.user.id}
            when 4 then jobs.sort_by {|job| dir * job.date.to_time.to_i}
            end
        end
      end
      filtered_jobs = jobs
      jobs = Kaminari.paginate_array(jobs).page(data['start'] / data['length'] + 1).per(data['length']) if data['length'] > 0
    end

    respond_to do |format|
      format.html
      format.json do
        render json: jobs, root: :jobs, meta: { total: total, filtered: filtered_jobs.then(:count) }
      end
    end
  end

  def export_all
    jobs = Job.standard.includes(booking: {property: {zip_code: {market: {}}}, user: {}})
    jobs = jobs.within_market(current_user.market) if current_user.market
    respond_to do |format|
      format.csv { send_data job_csv(jobs), filename: 'jobs.csv' }
    end
  end

  def export
    @jobs = params[:jobs].map {|id| Job.find id}
  end

  def metrics
    jobs = Job.standard
    jobs = jobs.within_market(current_user.market) if current_user.market
    total = jobs.standard.count
    next_ten = jobs.standard.where('jobs.date > ? and jobs.date < ?', Date.yesterday, Date.today + 10.days).count
    unclaimed = jobs.standard.where('jobs.status_cd = 0 and jobs.date > ? and jobs.date < ?', Date.yesterday, Date.today + 3.days).count
    completed = jobs.standard.on_month(Date.today - 1.month).count
    if completed > 0
      growth = (completed - jobs.standard.on_month(Date.today - 2.months).count) / completed
    else
      growth = 0
    end
    render json: { total: total, next_ten: next_ten, unclaimed: unclaimed, completed: completed, growth: growth }
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        job.current_user = current_user
        render json: job.to_json(methods: [:formatted_time, :payout, :payout_integer, :payout_fractional, :man_hours, :king_bed_count, :twin_bed_count, :toiletry_count, :checklist, :contractor_photos], include: {payouts: {include: {user: {methods: [:name, :display_phone_number]}}}, contractors: {methods: [:name, :display_phone_number], include: {contractor_profile: {methods: [:display_position]}}}, booking: {methods: [:cost], include: {services: {}, payment: {methods: :display}, property: {methods: [:primary_photo, :full_address, :nickname, :king_bed_count, :property_size], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}}}})
      end
    end
  end

  def clone
    new_booking = job.booking.dup
    job.booking.services.each {|service| new_booking.services.push service}
    job.booking.coupons.each {|coupon| new_booking.coupons.push coupon}
    new_booking.status_cd = 1
    new_booking.payment_status_cd = 0
    new_booking.timeslot_type_cd = 0
    new_booking.cloned = true
    if new_booking.save
      new_booking.update_cost!
      render json: { success: true, url: admin_job_url(new_booking.job) }
    else
      render json: { success: false }
    end
  end

  def available_times
    render json: job.check_times, root: :times
  end

  def edit_time
    contractor = User.find params[:contractor_id]
    if job.edit_time(params[:time])
      jobs = contractor.jobs.on_date(job.date).where('occasion_cd != 1 or distribution = ?', false)
      jobs.each {|j| j.current_user = contractor}
      render json: jobs.sort_by{|j| j.priority contractor}, root: :jobs, meta: { success: true }
    else
      render json: { meta: { success: false } }
    end
  end

  def contractors
    render json: job.contractors, each_serializer: JobContractorSerializer, root: :contractors
  end

  def update_extras
    job.booking.update_attributes(extra_king_sets: params[:extras][:king_sets],
                                  extra_twin_sets: params[:extras][:twin_sets],
                                  extra_toiletry_sets: params[:extras][:toiletry_sets])
    job.booking.update_cost!
    render json: { success: true, king_beds: job.king_bed_count, twin_beds: job.twin_bed_count, toiletries: job.toiletry_count, extra_king_sets: job.booking.extra_king_sets, extra_twin_sets: job.booking.extra_twin_sets, extra_toiletry_sets: job.booking.extra_toiletry_sets }
  end

  def update_instructions
    job.booking.update_attribute :extra_instructions, params[:extras][:instructions]
    render json: { success: true, extra_instructions: job.booking.extra_instructions }
  end

  def edit_payout
    payout = Payout.find params[:payout_id]
    adjusted   = params[:adjusted_cost].to_f   * 100
    overage    = params[:overage_cost].to_f    * 100
    discounted = params[:discounted_cost].to_f * 100

    if overage > 0
      payout.adjusted          = true
      payout.addition          = true
      payout.additional_amount = overage
      payout.additional_reason = params[:overage_reason]
      payout.adjusted_amount   = adjusted
    else
      payout.addition          = false
      payout.additional_amount = 0
      payout.additional_reason = ''
    end

    if discounted > 0
      payout.adjusted          = true
      payout.subtraction       = true
      payout.subtracted_amount = discounted
      payout.subtracted_reason = params[:discounted_reason]
      payout.adjusted_amount   = adjusted
    else
      payout.subtraction       = false
      payout.subtracted_amount = 0
      payout.subtracted_reason = ''
    end

    if payout.subtraction == false && payout.addition == false
      payout.adjusted = false
      payout.adjusted_amount = 0
    end

    payout.save

    total_payout = job.payouts.reduce(0) {|acc, payout| acc + payout.total}
    adjusted_payout = job.payouts.reduce(0) {|acc, payout| acc + payout.adjusted_amount}

    render json: { success: true, total_payout: total_payout / 100.0, adjusted_payout: adjusted_payout / 100.0 }
  end

  def booking_cost
    cost = job.booking.pricing_hash
    render json: cost
  end

  def add_contractor
    contractor = User.find params[:contractor_id]
    rsp = contractor.claim_job job, true
    if rsp[:success]
      TwilioJob.perform_later("+1#{contractor.phone_number}", "You have been assigned a new HostWise job on #{job.formatted_date}.")
      job.current_user = current_user
      render json: job.to_json(methods: [:formatted_time, :payout, :payout_integer, :payout_fractional, :man_hours, :king_bed_count, :twin_bed_count, :toiletry_count], include: {payouts: {include: {user: {methods: [:name, :display_phone_number]}}}, contractors: {methods: [:name, :display_phone_number], include: {contractor_profile: {methods: [:display_position]}}}, booking: {methods: [:cost], include: {services: {}, payment: {methods: :display}, property: {methods: [:primary_photo, :full_address, :nickname, :king_bed_count, :property_size], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}}}})
    else
      render json: { failure: true, message: rsp[:message] }
    end
  end

  def remove_contractor
    contractor = User.find params[:contractor_id]
    contractor.drop_job job, true
    job.current_user = current_user
    render json: job.to_json(methods: [:formatted_time, :payout, :payout_integer, :payout_fractional, :man_hours, :king_bed_count, :twin_bed_count, :toiletry_count], include: {payouts: {include: {user: {methods: [:name, :display_phone_number]}}}, contractors: {methods: [:name, :display_phone_number], include: {contractor_profile: {methods: [:display_position]}}}, booking: {methods: [:cost], include: {services: {}, payment: {methods: :display}, property: {methods: [:primary_photo, :full_address, :nickname, :king_bed_count, :property_size], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}}}})
  end

  def add_service
    service = Service.where(name: params[:service])[0]
    job.booking.services.push service
    job.booking.services.delete Service.where(name: 'preset')[0] if service.name == 'cleaning'
    job.booking.update_cost!
    render json: { success: true }
  end

  def remove_service
    service = Service.where(name: params[:service])[0]
    job.booking.services.delete service
    job.booking.services.push Service.where(name: 'preset')[0] if service.name == 'cleaning'
    job.booking.update_cost!
    render json: { success: true }
  end

  def update_status
    success = false; message = 'status update not allowed'
    if job.status_cd < 3 || job.status_cd == 4
      case params[:status]
      when 1
        success = true; message = nil
        job.scheduled!
      when 3
        success = true; message = nil
        job.complete!
      when 6
        success = true; message = nil
        job.update_attribute :status_cd, 6

        UserMailer.cancelled_booking_notification(job.booking).then(:deliver)

        if job.booking.same_day_cancellation
          job.booking.update_attribute :status, :cancelled
        else
          job.booking.update_attribute :status, :deleted
        end

        job.contractors.each do |contractor|
          contractor.payouts.create(job_id: job.id, amount: job.payout(contractor) * 100, payout_type_cd: 0) if job.booking.same_day_cancellation
          job.contractors.destroy contractor
          other_jobs = contractor.jobs.standard.on_date(job.date)
          if other_jobs[0]
            other_jobs[0].handle_distribution_jobs contractor
            Job.set_priorities contractor, job.date
          else
            contractor.jobs.distribution.on_date(job.date).destroy_all
          end
          if contractor.contractor_profile.position == :trainee
            TwilioJob.perform_later("+1#{contractor.phone_number}", "Oops! Your Test & Tips session on #{job.formatted_date} was cancelled. Please select another session!")
          else
            TwilioJob.perform_later("+1#{contractor.phone_number}", "Oops! Looks like job ##{job.id} on #{job.formatted_date} was cancelled. Sorry about this!")
          end
        end

        if job.booking.same_day_cancellation
          job.booking.update_cost!
          UserMailer.booking_same_day_cancellation(job.booking).then(:deliver)
        else
          UserMailer.booking_cancellation(job.booking).then(:deliver)
        end
      end
    end
    render json: { success: success, message: message, job: job.to_json(methods: [:formatted_time, :payout, :payout_integer, :payout_fractional, :man_hours, :king_bed_count, :twin_bed_count, :toiletry_count], include: {payouts: {include: {user: {methods: [:name, :display_phone_number]}}}, contractors: {methods: [:name, :display_phone_number], include: {contractor_profile: {methods: [:display_position]}}}, booking: {methods: [:cost], include: {services: {}, payment: {methods: :display}, property: {methods: [:primary_photo, :full_address, :nickname, :king_bed_count, :property_size], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}}}}) }
  end

  def update_state
    job.update_attribute :state_cd, params[:state]
    render json: { success: true, job: job.to_json(methods: [:formatted_time, :payout, :payout_integer, :payout_fractional, :man_hours, :king_bed_count, :twin_bed_count, :toiletry_count], include: {payouts: {include: {user: {methods: [:name, :display_phone_number]}}}, contractors: {methods: [:name, :display_phone_number], include: {contractor_profile: {methods: [:display_position]}}}, booking: {methods: [:cost], include: {services: {}, payment: {methods: :display}, property: {methods: [:primary_photo, :full_address, :nickname, :king_bed_count, :property_size], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}}}}) }
  end

  def available_contractors
    render json: User.contractors(params[:term]).to_json(include: {contractor_profile: {methods: [:display_position]}}, methods: [:name])
  end

end
