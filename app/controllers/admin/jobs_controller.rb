class Admin::JobsController < Admin::AuthController
  expose(:job) { Job.find params[:id] }
  
  def index
    jobs = Job.standard
    case params[:filter]
    when 'active'
      jobs = jobs.where(status_cd: [0,1])
    when 'future'
      jobs = jobs.future
    end
    jobs = jobs.search(params[:search]) if params[:search] && !params[:search].empty?
    jobs = jobs.order(params[:sort])
    jobs = jobs.reverse if params[:sort] && params[:sort] == 'id'

    respond_to do |format|
      format.html
      format.json do
        render json: jobs.to_json(include: {contractors: {methods: :name}, booking: {include: {property: {methods: [:nickname, :short_address], include: {user: {methods: :name}}}}}})
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: job.to_json(methods: [:payout_integer, :payout_fractional], include: {contractors: {methods: [:name, :display_phone_number]}, booking: {methods: [:cost], include: {services: {}, property: {methods: [:primary_photo, :full_address], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}}}})
      end
    end
  end

end
