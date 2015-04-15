class Admin::JobsController < Admin::AuthController
  expose(:job) { Job.find params[:id] }

  def index
    jobs = Job.standard
    case params[:filter]
    when 'complete'
      jobs = jobs.where(status_cd: [3,5,6])
    when 'active'
      jobs = jobs.where(status_cd: [0,1])
    when 'future'
      jobs = jobs.future_from_today 'America/Los_Angeles'
    end
    jobs = jobs.search(params[:search]) if params[:search] && !params[:search].empty?

    respond_to do |format|
      format.html
      format.json do
        render json: jobs.includes(contractors: {}, booking: {property: {user: {}}})
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        job.current_user = current_user
        render json: job.to_json(methods: [:payout, :payout_integer, :payout_fractional, :man_hours], include: {contractors: {methods: [:name, :display_phone_number], include: {contractor_profile: {methods: [:display_position]}}}, booking: {methods: [:cost], include: {services: {}, payment: {methods: :display}, property: {methods: [:primary_photo, :full_address, :nickname], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}}}})
      end
    end
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
      payout.adjusted_amount   = adjusted
    else
      payout.addition          = false
      payout.additional_amount = 0
    end

    if discounted > 0
      payout.adjusted          = true
      payout.subtraction       = true
      payout.subtracted_amount = discounted
      payout.adjusted_amount   = adjusted
    else
      payout.subtraction       = false
      payout.subtracted_amount = 0
    end

    if payout.subtraction == false && payout.addition == false
      payout.adjusted = false
      payout.adjusted_amount = 0
    end

    payout.save
    render json: { success: true }
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
      render json: job.to_json(methods: [:payout, :payout_integer, :payout_fractional], include: {contractors: {methods: [:name, :display_phone_number]}, booking: {methods: [:cost], include: {services: {}, property: {methods: [:primary_photo, :full_address, :nickname], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}}}})
    else
      render json: { failure: true, message: rsp[:message] }
    end
  end

  def remove_contractor
    contractor = User.find params[:contractor_id]
    contractor.drop_job job, true
    job.current_user = current_user
    render json: job.to_json(methods: [:payout, :payout_integer, :payout_fractional], include: {contractors: {methods: [:name, :display_phone_number]}, booking: {methods: [:cost], include: {services: {}, property: {methods: [:primary_photo, :full_address], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}}}})
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
    job.update_attribute :status_cd, params[:status]
    case job.status
    when :completed
      job.complete!
    when :cant_access
      job.booking.update_attribute :status_cd, 5
      job.booking.update_cost!
    end
    render json: { success: true }
  end

  def update_state
    job.update_attribute :state_cd, params[:state]
    render json: { success: true }
  end

  def available_contractors
    render json: User.search_contractors(params[:term]).to_json(methods: [:name])
  end

end
