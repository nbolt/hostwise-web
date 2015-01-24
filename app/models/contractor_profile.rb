class ContractorProfile < ActiveRecord::Base
  belongs_to :user

  before_validation :standardize_address

  as_enum :position, fired: 0, trainee: 1, contractor: 2, trainer: 3

  validates_numericality_of :emergency_contact_phone, only_integer: true, if: lambda { self.emergency_contact_phone.present? }
  validates_length_of :emergency_contact_phone, is: 10, if: lambda { self.emergency_contact_phone.present? }

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
end
