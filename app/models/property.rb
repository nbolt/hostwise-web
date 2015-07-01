class Property < ActiveRecord::Base
  extend FriendlyId
  include PgSearch

  acts_as_commentable

  friendly_id :slug_candidates, use: :slugged

  pg_search_scope :search_property, against: [:id, :title, :address1, :address2, :city, :zip], using: { tsearch: { prefix: true } }

  as_enum :rental_type, full_time: 0, part_time: 1
  as_enum :property_type, house: 0, condo: 1
  as_enum :linen_handling, purchase: 0, rental: 1, in_unit: 2

  belongs_to :user
  belongs_to :zip_code, foreign_key: :zip_id
  has_many :bookings, autosave: true, dependent: :destroy
  has_many :active_bookings, -> { active.order(:date) }, autosave: true, dependent: :destroy, class_name: 'Booking'
  has_many :past_bookings, -> { where('bookings.status_cd in (3,5)').order(:date) }, class_name: 'Booking'
  has_many :property_photos, autosave: true, dependent: :destroy
  has_many :property_transactions, class_name: 'PropertyTransactions', dependent: :destroy
  has_many :transactions, through: :property_transactions, source: :stripe_transaction

  before_validation :standardize_address
  before_save :fetch_zone, :assign_zip

  validates_numericality_of :phone_number, only_integer: true, if: lambda { self.phone_number.present? }
  validates_length_of :phone_number, is: 10, if: lambda { self.phone_number.present? }
  validates_presence_of :access_info, :parking_info, :trash_disposal, :restocking_info, if: lambda { step == 3 }

  scope :within_market, -> (market) { where('markets.id = ?', market.id).references(:markets).includes(zip_code: :market) || where(id:nil) }
  scope :not_purchased, -> { where('linen_handling_cd > 0') }
  scope :purchased, -> { where('linen_handling_cd = 0 and purchase_date is not null') }
  scope :has_upcoming, -> { where('bookings.date >= ? and bookings.date <= ?', Date.today - 2.weeks, Date.today).includes(:bookings).references(:bookings) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_user, -> (user) { where(user_id: user.id) }
  scope :by_alphabetical, -> { reorder('LOWER(title)') }
  scope :upcoming_bookings, -> { where('bookings.id is not null').where('date >= ?', Date.today).includes(:active_bookings).references(:active_bookings) }
  scope :no_upcoming, -> { where('bookings.id is null').includes(:active_bookings).references(:active_bookings) }
  scope :recently_added, -> { reorder('created_at DESC') }
  scope :purchase_on_month, -> (date) { where('linen_handling_cd = 0 and purchase_date is not null and extract(month from properties.purchase_date) = ? and extract(year from properties.purchase_date) = ?', date.month, date.year) }

  attr_accessor :step

  def self.find_by_slug slug
    friendly.find slug
  rescue ActiveRecord::RecordNotFound
  end

  def self.order_by_upcoming
    upcoming_bookings.active.sort_by(&:next_service_date) + no_upcoming.active
  end

  def revenue
    Transaction.where('booking_transactions.booking_id in (?)', bookings.map(&:id)).includes(:booking_transactions).references(:booking_transactions).sum(:amount) / 100.0
  end

  def linen_purchase_revenue
    transactions.reduce(0) {|acc, transaction| acc + (transaction.amount / 100.0 || 0)}
  end

  def last_transaction
    transactions.order(charged_at: :asc, created_at: :asc).last
  end

  def next_service_date
    bookings.where(status_cd: [1,4]).future.order(:date).first.then(:date)
  end

  def last_service_date
    last_booking.then :date
  end

  def last_booking
    bookings.completed.order('date desc')[0]
  end

  def turnover_rate
    rates = []
    bookingz = bookings.completed.order('date')
    if bookingz.count > 1
      (bookingz.count-1).times {|i| rates.push([bookingz[i], bookingz[i+1]])}
      rates.map! {|bookings| (bookings[1].date - bookings[0].date).to_i}
      "#{rates.sum / rates.count} days"
    else
      'n/a'
    end
  end

  def self.search(term, sort=nil)
    results = Property.all
    results = results.search_property(term) if term.present? && !results.empty? && sort != 'upcoming_service' # NEEDS FIX
    if sort
      case sort
        when 'alphabetical'
          results = results.by_alphabetical.active
        when 'recently_added'
          results = results.recently_added.active
        when 'upcoming_service'
          results = results.order_by_upcoming
        when 'deactivated'
          results = results.inactive
      end
    else
      results = results.active
    end
    results
  end

  def nickname
    title || address1
  end

  def display_created_at
    created_at.strftime('%Y-%m-%d')
  end

  def display_phone_number
    number = phone_number.present? && phone_number || user.phone_number
    if number.present?
      first  = number[0..2]
      second = number[3..5]
      third  = number[6..9]
      "(#{first}) #{second}-#{third}"
    else
      ''
    end
  end

  def short_address
    "#{address1} #{zip}"
  end

  def neighborhood_address
    zip = ZipCode.where(code: self.zip)[0]
    if zip
      neighborhood = zip.chain(:neighborhood, :name)
      if neighborhood && neighborhood != city
        "#{address1}, #{neighborhood}, #{zip.code}"
      else
        "#{address1}, #{city}, #{zip.code}"
      end
    else
      "#{address1}, #{city}, #{self.zip}"
    end
  end

  def full_address
    if address2
      "#{address1} #{address2}, #{city}, #{state} #{zip}"
    else
      "#{address1}, #{city}, #{state} #{zip}"
    end
  end

  def full_address_encoded
    CGI::escape full_address
  end

  def map_address
    "#{address1}, #{city}, #{state} #{zip}"
  end

  def beds
    king_beds + queen_beds + full_beds + twin_beds
  end

  def king_bed_count
    king_beds + queen_beds + full_beds
  end

  def neighborhood
    zip = ZipCode.where(code: self.zip)[0]
    if zip
      if zip.neighborhood && zip.neighborhood.name != city
        "#{zip.neighborhood.name}, #{city}, #{zip.code}"
      else
        "#{city}, #{zip.code}"
      end
    else
      ''
    end
  end

  def primary_photo
    if property_photos.present?
      property_photos.first.photo.url
    else
      '/images/generic_property_with_circle.png'
    end
  end

  def property_size
    "#{rooms} #{property_type.to_s.titleize}"
  end

  def rooms
    "#{bedrooms}BD/#{bathrooms}BA"
  end

  private

  def assign_zip
    self.zip_code = ZipCode.where(code: self.zip)[0]
  end

  def fetch_zone
    if !zone && lng
      timezone = Timezone::Zone.new :latlon => [lat, lng]
      self.zone = timezone.zone
    end
  end

  def standardize_address
    if address_changed?
      address = SmartyStreets::StreetAddressRequest.new(street: address1, street2: address2, zipcode: zip)
      rsp = SmartyStreets::StreetAddressApi.call(address)
      if rsp[0]
        address = rsp[0].to_hash
        self.delivery_point_barcode = address[:delivery_point_barcode]
        self.address1 = "#{address[:components][:primary_number]} #{address[:components][:street_predirection]} #{address[:components][:street_name]} #{address[:components][:street_suffix]}".squish
        self.address2 = "#{address[:components][:secondary_designator]} #{address[:components][:secondary_number]}" if address[:components][:secondary_designator]
        self.zip = address[:components][:zipcode]
        self.city = address[:components][:city_name]
        self.state = address[:components][:state_abbreviation]
        self.lat = address[:metadata][:latitude]
        self.lng = address[:metadata][:longitude]
      else
        errors[:base] << 'Invalid address'
      end
    end
  end

  def address_changed?
    address1_changed? || address2_changed? || city_changed? || state_changed? || zip_changed?
  end

  def slug_candidates
    [
      :nickname,
      [:nickname, :id]
    ]
  end
end
