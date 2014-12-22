class Property < ActiveRecord::Base
  belongs_to :user
  has_many :bookings, autosave: true, dependent: :destroy

  before_validation :standardize_address

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
    else
      errors[:base] << 'Address not found'
    end
  end
end
