class Admin::CouponsController < Admin::AuthController
  expose(:coupon) { Coupon.find params[:id] }

  def index
    coupons = Coupon.all

    respond_to do |format|
      format.html
      format.json do
        render json: coupons
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

  def create
    coupon = Coupon.new coupon_params
    coupon.expiration = Date.strptime params[:coupon][:expiration], '%m/%d/%Y' if params[:coupon][:expiration]
    coupon.amount = params[:coupon][:amount].to_f * 100 if coupon.discount_type_cd == 0
    if coupon.save
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def update
    coupon.update_attributes coupon_params
    coupon.expiration = Date.strptime params[:coupon][:expiration], '%m/%d/%Y' if params[:coupon][:expiration]
    coupon.amount = params[:coupon][:amount].to_f * 100 if coupon.discount_type_cd == 0
    coupon.limit ||= 0
    if coupon.save
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  private

  def coupon_params
    params.require(:coupon).permit(:description, :code, :status_cd, :amount, :limit, :expiration, :discount_type_cd)
  end

end
