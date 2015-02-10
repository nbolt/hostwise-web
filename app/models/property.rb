class Property < ActiveRecord::Base
  extend FriendlyId
  include PgSearch

  friendly_id :slug_candidates, use: :slugged

  pg_search_scope :search_property, against: [:title, :address1, :city, :zip], using: { tsearch: { prefix: true } }

  belongs_to :user
  has_many :bookings, autosave: true, dependent: :destroy
  has_many :property_photos, autosave: true, dependent: :destroy

  before_validation :standardize_address

  validates_numericality_of :phone_number, only_integer: true, if: lambda { self.phone_number.present? }
  validates_length_of :phone_number, is: 10, if: lambda { self.phone_number.present? }
  validates_presence_of :access_info, :parking_info, :trash_disposal

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_user, -> (user) { where(user_id: user.id) }
  scope :by_alphabetical, -> { reorder('LOWER(title)') }
  scope :upcoming_bookings, -> { includes(:bookings).where('bookings.id is not null').order('bookings.created_at DESC').references(:bookings) }
  scope :recently_added, -> { reorder('created_at DESC') }

  def self.find_by_slug slug
    friendly.find slug
  rescue ActiveRecord::RecordNotFound
  end

  def next_service_date
    bookings.future.order(:date).first.then(:date)
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

  def primary_photo
    if property_photos.empty?
      '' #will add a default placeholder later
    else
      property_photos.first.photo.url
    end
  end

  private

  def standardize_address
    address = SmartyStreets::StreetAddressRequest.new(street: address1, street2: address2, zipcode: zip)
    rsp = SmartyStreets::StreetAddressApi.call(address)
    if rsp[0]
      address = rsp[0].to_hash
      self.delivery_point_barcode = address[:delivery_point_barcode]
      self.address1 = "#{address[:components][:primary_number]} #{address[:components][:street_name]} #{address[:components][:street_suffix]}"
      self.address2 = "#{address[:components][:secondary_designator]} #{address[:components][:secondary_number]}" if address[:components][:secondary_designator]
      self.zip = address[:components][:zipcode]
      self.city = address[:components][:city_name]
      self.state = address[:components][:state_abbreviation]
    else
      errors[:base] << 'Invalid address'
    end
  end

  def slug_candidates
    [
      :nickname,
      [:nickname, :id]
    ]
  end
end
