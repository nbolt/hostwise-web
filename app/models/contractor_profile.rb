class ContractorProfile < ActiveRecord::Base
  belongs_to :user

  before_validation :standardize_address
  before_save :create_stripe_recipient, :fetch_zone, :handle_position_change

  as_enum :position, fired: 0, trainee: 1, contractor: 2, trainer: 3

  attr_encrypted :ssn, :driver_license, key: ENV['CIPHER_KEY']

  validates_presence_of :address1, :zip
  validates_numericality_of :emergency_contact_phone, only_integer: true, if: lambda { self.emergency_contact_phone.present? }
  validates_length_of :emergency_contact_phone, is: 10, if: lambda { self.emergency_contact_phone.present? }

  def current_position
    {id: position_cd.to_s, text: display_position.upcase}
  end

  def display_position
    case position
      when :fired
        'fired'
      when :trainee
        'applicant'
      when :contractor
        'contractor'
      when :trainer
        'mentor'
    end
  end

  def test_session_completed
    return false if position == :trainee && user.jobs.training.not_complete.count > 0
    true
  end

  private

  def fetch_zone
    if !zone && lng
      timezone = Timezone::Zone.new :latlon => [lat, lng]
      self.zone = timezone.zone
    end
  end

  def create_stripe_recipient
    unless stripe_recipient_id
      rsp = Stripe::Account.create(
        :managed => true,
        :country => 'US',
        :email => user.email
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

  def handle_position_change
    if user && position_cd_changed?
      if position == :contractor && (position_cd_was == 3 || position_cd_was == 1)
        user.jobs.training.each {|job| user.drop_job job, true}
      elsif position == :fired
        user.deactivate!
      end
    end
  end
end
