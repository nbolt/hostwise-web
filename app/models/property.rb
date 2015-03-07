class Property < ActiveRecord::Base
  extend FriendlyId
  include PgSearch

  friendly_id :slug_candidates, use: :slugged

  pg_search_scope :search_property, against: [:id, :title, :address1, :city, :zip], using: { tsearch: { prefix: true } }

  as_enum :rental_type, full_time: 0, part_time: 1
  as_enum :property_type, house: 0, condo: 1

  belongs_to :user
  has_many :bookings, autosave: true, dependent: :destroy
  has_many :active_bookings, -> { where(status_cd: [1,4]) }, autosave: true, dependent: :destroy, class_name: 'Booking'
  has_many :future_bookings, -> { where('date >= ?', Date.today).where(status_cd: [1,4]).order(:date) }, class_name: 'Booking'
  has_many :past_bookings, -> { where(status_cd: 3).order(:date) }, class_name: 'Booking'
  has_many :property_photos, autosave: true, dependent: :destroy

  before_validation :standardize_address

  validates_numericality_of :phone_number, only_integer: true, if: lambda { self.phone_number.present? }
  validates_length_of :phone_number, is: 10, if: lambda { self.phone_number.present? }
  validates_presence_of :access_info, :parking_info, :trash_disposal, :restocking_info, if: lambda { step == 3 }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_user, -> (user) { where(user_id: user.id) }
  scope :by_alphabetical, -> { reorder('LOWER(title)') }
  scope :upcoming_bookings, -> { where('bookings.id is not null').order('bookings.created_at DESC').includes(:active_bookings).references(:active_bookings) }
  scope :recently_added, -> { reorder('created_at DESC') }

  attr_accessor :step

  def self.find_by_slug slug
    friendly.find slug
  rescue ActiveRecord::RecordNotFound
  end

  def next_service_date
    bookings.where(status_cd: [1,4]).future.order(:date).first.then(:date)
  end

  def self.search(term, sort=nil)
    if sort
      case sort
        when 'alphabetical'
          results = by_alphabetical.active
        when 'recently_added'
          results = recently_added.active
        when 'upcoming_service'
          results = upcoming_bookings.active
        when 'deactivated'
          results = inactive
      end
    else
      results = Property.active
    end
    return results.search_property(term) if term.present? && !results.empty?
    results
  end

  def nickname
    title || address1
  end

  def short_address
    "#{address1} #{zip}"
  end

  def full_address
    if address2
      "#{address1} #{address2}, #{city}, #{state} #{zip}"
    else
      "#{address1}, #{city}, #{state} #{zip}"
    end
  end

  def beds
    king_beds + queen_beds + full_beds + twin_beds
  end

  def neighborhood
    zip = Zip.where(code: self.zip)[0]
    if zip
      if zip.neighborhood && zip.neighborhood.name != city
        "#{zip.neighborhood.name}, #{city}"
      else
        city
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
    "#{bedrooms}BD/#{bathrooms}BA #{property_type.to_s.titleize}"
  end

  private

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
