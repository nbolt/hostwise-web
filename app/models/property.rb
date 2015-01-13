class Property < ActiveRecord::Base
  extend FriendlyId
  include PgSearch

  friendly_id :slug_candidates, use: :slugged

  pg_search_scope :search_property, against: [:title, :address1, :city, :zip], using: { tsearch: { prefix: true } }

  belongs_to :user
  has_many :bookings, autosave: true, dependent: :destroy
  has_many :property_photos, autosave: true, dependent: :destroy

  before_validation :standardize_address, on: :create

  scope :by_user, -> (user) { where(user_id: user.id) }

  def self.find_by_slug slug
    friendly.find slug
  rescue ActiveRecord::RecordNotFound
  end

  def self.search(query)
    if query.present?
      search_property(query).reorder('LOWER(title)')
    else
      order('LOWER(title)')
    end
  end

  def short_address
    "#{address1} #{zip}"
  end

  private

  def standardize_address
    address = SmartyStreets::StreetAddressRequest.new(street: address1, street2: address2, city: city, state: state, zipcode: zip)
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
      :title,
      [:title, :id]
    ]
  end
end
