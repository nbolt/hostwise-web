class DistributionCenter < ActiveRecord::Base
  has_many :jobs, through: :job_distribution_centers
  has_many :job_distribution_centers, dependent: :destroy

  before_save :standardize_address

  attr_accessor :distance

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

  def short_address
    "#{address1} #{zip}"
  end

  private

  def standardize_address
    if address_changed?
      address = SmartyStreets::StreetAddressRequest.new(street: address1, street2: address2, zipcode: zip)
      rsp = SmartyStreets::StreetAddressApi.call(address)
      if rsp[0]
        address = rsp[0].to_hash
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
end
