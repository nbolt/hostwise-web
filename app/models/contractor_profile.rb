class ContractorProfile < ActiveRecord::Base
  belongs_to :user

  before_save :standardize_address, :create_stripe_recipient

  as_enum :position, fired: 0, trainee: 1, contractor: 2, trainer: 3

  attr_encrypted :ssn, :driver_license, key: ENV['CIPHER_KEY']

  validates_presence_of :address1, :zip
  validates_numericality_of :emergency_contact_phone, only_integer: true, if: lambda { self.emergency_contact_phone.present? }
  validates_length_of :emergency_contact_phone, is: 10, if: lambda { self.emergency_contact_phone.present? }

  def current_position
    {id: position_cd.to_s, text: position.upcase}
  end

  private

  def create_stripe_recipient
    if ssn? && !stripe_recipient_id
      rsp = Stripe::Recipient.create(
        :name => user.name,
        :tax_id => Rails.env.production? ? ssn : '000000000',
        :type => 'individual'
      )
      self.stripe_recipient_id = rsp.id
    end
  end

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
