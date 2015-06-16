class Booking < ActiveRecord::Base
  include PgSearch
  pg_search_scope :search, against: [:id], associated_against: {user: [:first_name, :last_name, :email], property: [:title, :address1, :city, :state, :zip, :user_id]}, using: { tsearch: { prefix: true } }

  belongs_to :property
  belongs_to :payment

  has_one :job, autosave: true, dependent: :destroy
  has_one :user, through: :booking_users
  has_one :booking_users, dependent: :destroy
  has_many :booking_services, class_name: 'BookingServices', dependent: :destroy
  has_many :services, through: :booking_services
  has_many :booking_coupons, class_name: 'BookingCoupon', dependent: :destroy
  has_many :coupons, through: :booking_coupons
  has_many :booking_transactions, class_name: 'BookingTransactions', dependent: :destroy
  has_many :transactions, through: :booking_transactions, source: :stripe_transaction
  has_many :successful_transactions, -> { where(status_cd: 0) },  through: :booking_transactions, source: :stripe_transaction

  scope :on_date, -> (date) {
    date = date.to_date if date.class == Time
    where(date: date)
  }
  scope :on_month, -> (date) { where('extract(month from bookings.date) = ? and extract(year from bookings.date) = ?', date.month, date.year) }
  scope :pending, -> { where('services.id is null or bookings.payment_id is null').includes(:services).references(:services) }
  scope :today, -> { where('date = ?', Date.today) }
  scope :tomorrow, -> { where('date = ?', Date.today + 1) }
  scope :upcoming, -> (user) { where(status_cd: [1,4]).where('bookings.property_id = properties.id and properties.user_id = ? and bookings.date > ?', user.id, Date.today).order(date: :asc).includes(:property).references(:property) }
  scope :complete, -> (user) { where(status_cd: [3,5]).where('bookings.property_id = properties.id and properties.user_id = ? and bookings.date <= ?', user.id, Date.today).order(date: :asc).includes(:property).references(:property) }
  scope :future, -> { where('date >= ?', Date.today) }
  scope :past, -> { where('date < ?', Date.today) }
  scope :by_user, -> (user) { where('user_id = ? and bookings.status_cd != ?', user.id, 0).includes(property: [:user]).references(:user) }
  scope :active, -> { where(status_cd: 1) }
  scope :completed, -> {where(status_cd: 3) }

  before_save :check_transaction, :update_linen_handling
  before_create :create_job
  after_create :attach_user

  as_enum :status, deleted: 0, active: 1, cancelled: 2, completed: 3, manual: 4, couldnt_access: 5
  as_enum :payment_status, pending: 0, completed: 1
  as_enum :linen_handling, purchase: 0, rental: 1, in_unit: 2
  as_enum :timeslot_type, flex: 0, premium: 1

  attr_accessor :vip

  def preset_cost
    staging_cost
  end

  def linens_cost
    linen_cost
  end

  def service_list
    services.map(&:display).join ', '
  end

  def linen_set_count
    job.king_bed_count + job.twin_bed_count
  end

  def self.cost property, services, linen_handling, timeslot_type, timeslot, extra_king_sets = false, extra_twin_sets = false, extra_toiletry_sets = false, first_booking_discount = false, late_next_day = false, late_same_day = false, no_access_fee = false, coupon_id = false, date=nil, dates=nil
    pool_service = Service.where(name: 'pool')[0]
    rsp = {cost:0}
    services.each do |service|
      case service.name
        when 'cleaning'
          rsp[:cleaning] = PRICING[property.property_type.to_s][property.bedrooms][property.bathrooms]
        when 'linens'
          rsp[:linens] ||= 0
          property.beds.times { rsp[:linens] += PRICING['linens'][linen_handling.then(:to_s) || 'rental'] }
          rsp[:cost] += rsp[:linens]
        when 'toiletries'
          rsp[:toiletries] ||= 0
          property.bathrooms.times  { rsp[:toiletries] += PRICING['toiletries']  }
          rsp[:cost] += rsp[:toiletries]
        when 'pool'
          rsp[:pool] = PRICING['pool']
        when 'patio'
          rsp[:patio] = PRICING['patio']
        when 'windows'
          rsp[:windows] = PRICING['windows']
        when 'preset'
          rsp[:preset] = PRICING['preset'][property.beds]
      end
    end
    rsp[:contractor_service_cost] = (rsp[:cleaning] || 0) + (rsp[:pool] || 0) + (rsp[:patio] || 0) + (rsp[:windows] || 0) + (rsp[:preset] || 0)
    rsp[:orig_service_cost] = rsp[:contractor_service_cost]
    if timeslot_type != :flex
      case timeslot.to_i
      when 9  then rsp[:contractor_service_cost] *= PRICING['timeslots'][9]
      when 10 then rsp[:contractor_service_cost] *= PRICING['timeslots'][10]
      when 11 then rsp[:contractor_service_cost] *= PRICING['timeslots'][11]
      when 12 then rsp[:contractor_service_cost] *= PRICING['timeslots'][12]
      when 13 then rsp[:contractor_service_cost] *= PRICING['timeslots'][13]
      when 14 then rsp[:contractor_service_cost] *= PRICING['timeslots'][14]
      when 15 then rsp[:contractor_service_cost] *= PRICING['timeslots'][15]
      when 16 then rsp[:contractor_service_cost] *= PRICING['timeslots'][16]
      when 17 then rsp[:contractor_service_cost] *= PRICING['timeslots'][17]
      when 18 then rsp[:contractor_service_cost] *= PRICING['timeslots'][18]
      end
    end
    rsp[:contractor_service_cost] = rsp[:contractor_service_cost].round
    rsp[:timeslot_cost] = rsp[:contractor_service_cost] - rsp[:orig_service_cost]
    rsp[:cost] += rsp[:contractor_service_cost]
    if late_next_day
      rsp[:late_next_day] = PRICING['late_next_day']
      rsp[:cost] += PRICING['late_next_day']
    end
    if late_same_day
      rsp[:late_same_day] = PRICING['late_same_day']
      rsp[:cost] += PRICING['late_same_day']
    end
    if no_access_fee
      rsp[:no_access_fee] = PRICING['no_access_fee']
      rsp[:cost] += PRICING['no_access_fee']
    end
    if extra_king_sets # this tracks extra queen or full sets
      rsp[:extra_king_sets] ||= 0
      extra_king_sets.to_i.times { rsp[:extra_king_sets] += PRICING['linens']['rental'] }
      rsp[:cost] += rsp[:extra_king_sets]
    end
    if extra_twin_sets # this tracks extra twin sets
      rsp[:extra_twin_sets] ||= 0
      extra_twin_sets.to_i.times { rsp[:extra_twin_sets] += PRICING['linens']['rental'] }
      rsp[:cost] += rsp[:extra_twin_sets]
    end
    if extra_toiletry_sets # this tracks extra toiletry sets
      rsp[:extra_toiletry_sets] ||= 0
      extra_toiletry_sets.to_i.times { rsp[:extra_toiletry_sets] += PRICING['toiletries'] }
      rsp[:cost] += rsp[:extra_toiletry_sets]
    end
    if coupon_id
      coupon = Coupon.find coupon_id
      if coupon && coupon.status == :active && (coupon.limit == 0 || coupon.applied(property.user) < coupon.limit) && (coupon.users.empty? || coupon.users.find(property.user.id)) && (if date then (!coupon.expiration || coupon.expiration >= date) elsif dates then dates.any? {|k,v| if v then v.any? {|day| month=k.split('-')[0];year=k.split('-')[1];date=Date.strptime("#{month}-#{year}-#{day}", '%m-%Y-%d');coupon.expiration >= date} end} end)
        amount = coupon.amount
        amount /= 100.0 if coupon.discount_type == :dollar
        amount = rsp[:cost] * (coupon.amount / 100.0) if coupon.discount_type == :percentage
        if amount <= rsp[:cost]
          rsp[:coupon_cost] = amount * 100
        else
          rsp[:coupon_cost] = rsp[:cost] * 100
        end
        rsp[:cost] -= (rsp[:coupon_cost] / 100.0)
        rsp[:valid_dates] = dates.map {|k,v| if v then v.map {|day| month=k.split('-')[0];year=k.split('-')[1];date=Date.strptime("#{month}-#{year}-#{day}", '%m-%Y-%d');coupon.expiration >= date && date.strftime || nil} end}.flatten.compact if dates
      end
    end
    if first_booking_discount
      discount = PRICING['first_booking_discount']
      if discount <= rsp[:cost]
        rsp[:first_booking_discount] = discount
      else
        rsp[:first_booking_discount] = rsp[:cost]
      end
      rsp[:cost] -= rsp[:first_booking_discount]
    end
    rsp
  end

  def cost
    total_cost = (adjusted_cost + (contractor_service_cost*100) + (linen_cost*100) + (toiletries_cost*100) + (late_next_day_cost*100) + (late_same_day_cost*100) + (no_access_fee_cost*100) + (extra_king_sets_cost*100) + (extra_twin_sets_cost*100) + (extra_toiletry_sets_cost*100) - (first_booking_discount_cost*100) - coupon_cost) / 100.0
    if cancelled? || couldnt_access?
      total_cost -= linen_cost
      total_cost -= toiletries_cost
      total_cost -= extra_king_sets_cost
      total_cost -= extra_twin_sets_cost
      total_cost -= extra_toiletry_sets_cost
      total_cost = 0 if total_cost < 0
      [PRICING['cancellation'], (total_cost * 0.2).round(2)].max
    else
      total_cost = 0 if total_cost < 0
      total_cost
    end
  end

  def coupon_dollar_cost
    coupon_cost > 0 && coupon_cost / 100.0 || 0
  end

  def refunded_dollar_cost
    refunded_cost > 0 && refunded_cost / 100.0 || 0
  end

  def original_cost
    (cost - (adjusted_cost / 100.0)).round 2
  end

  def prediscount_cost
    if cancelled? || couldnt_access?
      cost
    else
      cost + first_booking_discount_cost + coupon_dollar_cost
    end
  end

  def pricing_hash
    { cost: cost,
      cleaning: cleaning_cost,
      linens: linen_cost,
      toiletries: toiletries_cost,
      pool: pool_cost,
      patio: patio_cost,
      windows: windows_cost,
      preset: staging_cost,
      no_access_fee: no_access_fee_cost,
      late_next_day: late_next_day_cost,
      late_same_day: late_same_day_cost,
      extra_king_sets: extra_king_sets_cost,
      extra_twin_sets: extra_twin_sets_cost,
      extra_toiletry_sets: extra_toiletry_sets_cost,
      first_booking_discount: first_booking_discount_cost,
      refunded_cost: refunded_cost / 100.0,
      overage_cost: overage_cost / 100.0,
      discounted_cost: discounted_cost / 100.0
    }
  end

  def process_refund! amount, reason=nil
    if last_transaction.then(:status) == :successful && !stripe_refund_id
      charge = Stripe::Charge.retrieve(last_transaction.stripe_charge_id)
      begin
        refund = charge.refunds.create(amount: amount, metadata: {booking_id: self.id, reason: reason})
        self.update_attribute :stripe_refund_id, refund.id
        true
      rescue Stripe::InvalidRequestError
        false
      end
    else
      false
    end
  end

  def update_cost!
    cost = Booking.cost(property, services, linen_handling, timeslot_type, timeslot, extra_king_sets, extra_twin_sets, extra_toiletry_sets, first_booking_discount, late_next_day, late_same_day, no_access_fee, self.chain(:coupons, :first, :id), date)
    self.timeslot_cost               = cost[:timeslot_cost] || 0
    self.contractor_service_cost     = cost[:contractor_service_cost] || 0
    self.cleaning_cost               = cost[:cleaning] || 0
    self.linen_cost                  = cost[:linens] || 0
    self.toiletries_cost             = cost[:toiletries] || 0
    self.pool_cost                   = cost[:pool] || 0
    self.patio_cost                  = cost[:patio] || 0
    self.windows_cost                = cost[:windows] || 0
    self.staging_cost                = cost[:preset] || 0
    self.no_access_fee_cost          = cost[:no_access_fee] || 0
    self.late_next_day_cost          = cost[:late_next_day] || 0
    self.late_same_day_cost          = cost[:late_same_day] || 0
    self.first_booking_discount_cost = cost[:first_booking_discount] || 0
    self.extra_king_sets_cost        = cost[:extra_king_sets] || 0
    self.extra_twin_sets_cost        = cost[:extra_twin_sets] || 0
    self.extra_toiletry_sets_cost    = cost[:extra_toiletry_sets] || 0
    self.coupon_cost                 = cost[:coupon_cost] || 0
    self.save
  end

  def send_reminder
    # notify host
    UserMailer.booking_reminder(self, self.property.user).then(:deliver) if self.property.user.settings(:service_reminder).email

    # notify contractor
    if self.job
      self.job.contractors.each do |contractor|
        UserMailer.booking_reminder(self, contractor).then(:deliver) if contractor.settings(:service_reminder).email
        if contractor.settings(:service_reminder).sms && !contractor.deactivated?
          pickup_job = contractor.jobs.on_date(self.date).pickup[0]
          sms = "Tomorrow you have a HostWise job at #{self.property.short_address}."
          sms += " Don't forget to pick up supplies at 9:30 at #{pickup_job.distribution_center.short_address}." if pickup_job
          TwilioJob.perform_later("+1#{contractor.phone_number}", sms)
        end
      end
    end
  end

  def charge!
    if self.payment_status == :completed
      false
    elsif cost == 0
      self.update_attribute :payment_status_cd, 1
    elsif payment.stripe_id
      amount = (cost * 100).to_i
      begin
        metadata = { job_id: job.id, booking_id: self.id, user_id: user.id, user_email: user.email, service_date: self.date.to_s }
        if cancelled?
          metadata[:cancellation] = true
        elsif couldnt_access?
          metadata[:couldnt_access] = true
        end
        rsp = Stripe::Charge.create(
          amount: amount,
          currency: 'usd',
          customer: property.user.stripe_customer_id,
          source: payment.stripe_id,
          statement_descriptor: "HostWise #{id}"[0..21], # 22 characters max
          metadata: metadata
        )
        transactions.create(stripe_charge_id: rsp.id, status_cd: 0, amount: amount, transaction_type_cd: 0)
        save
        UserMailer.service_completed(self).then(:deliver) if user.settings(:service_completion).email
        true
      rescue Stripe::CardError => e
        err  = e.json_body[:error]
        transactions.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message], amount: amount, transaction_type_cd: 0)
        UserMailer.generic_notification("Stripe Payment Failed - ***#{payment.last4}: #{property.user.name}", "Booking ID: #{id}").then(:deliver)
        false
      end
    else
      false
    end
  end

  def last_transaction
    transactions.order(charged_at: :asc, created_at: :asc).last
  end

  def same_day_cancellation
    timezone = Timezone::Zone.new :zone => property.zone
    day = (self.date.to_date - timezone.time(Time.now).to_date).to_i
    return true if day == 0 || (day == 1 && timezone.time(Time.now).hour >= 22) # subject to cancellation if same day or the day before after 10pm
    return false
  end

  def next_day_cancellation
    timezone = Timezone::Zone.new :zone => property.zone
    day = (self.date.to_date - timezone.time(Time.now).to_date).to_i
    return true if day == 0 || day == 1 # subject to cancellation if same day or the day before
    return false
  end

  def formatted_date
    date.strftime '%m/%d/%Y'
  end

  def duplicate?
    existing_booking = property.bookings.active.on_date(date)[0]
    if existing_booking
      if existing_booking == self
        false
      else
        true
      end
    else
      false
    end
  end

  private

  def create_job
    if status_cd != 4
      job = self.build_job(status_cd: 0, date: date)
      job.state_cd = 1 if vip
      job.size = 2 if ((property.bedrooms == 3 && property.bathrooms >= 3) || property.bedrooms > 3) && !services.where(name: 'preset')[0]
    end
  end

  def check_transaction
    if self.payment_status != :completed && transactions.where(status_cd:0).count > 0
      self.payment_status = :completed
    end
  end

  def update_linen_handling
    self.linen_handling_cd = nil unless services.where(name: 'linens')[0] || !id
  end

  def attach_user
    self.user = property.user
  end

end
