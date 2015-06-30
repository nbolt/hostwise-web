class ContractorProfile < ActiveRecord::Base
  belongs_to :user
  belongs_to :market

  mount_uploader :document, DocumentUploader

  before_validation :standardize_address
  before_save :create_stripe_recipient, :fetch_zone, :handle_position_change

  as_enum :position, fired: 0, trainee: 1, contractor: 2, trainer: 3, elite: 4

  attr_encrypted :ssn, :driver_license, key: ENV['CIPHER_KEY']

  validates_presence_of :address1, :zip
  validates_numericality_of :emergency_contact_phone, only_integer: true, if: lambda { self.emergency_contact_phone.present? }
  validates_length_of :emergency_contact_phone, is: 10, if: lambda { self.emergency_contact_phone.present? }

  def current_position
    {id: position_cd.to_s, text: display_position.upcase}
  end

  def market_hash
    {id: market.id, text: market.name} if market
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
      when :elite
        'elite'
    end
  end

  def test_session_completed
    return false if position == :trainee && user.jobs.training.not_complete.count > 0
    true
  end

  def verify_stripe!(ip=nil)
    if self.stripe_recipient_id
      ip = Socket.ip_address_list.detect(&:ipv4_private?).try(:ip_address) unless ip
      ip = IPSocket::getaddress('www.hostwise.com') unless ip
      begin
        account = Stripe::Account.retrieve self.stripe_recipient_id
        if account.verification.fields_needed[0]
          account.tos_acceptance = { date: Time.now.to_i, ip: ip }
          account.legal_entity = { 'type' => 'individual', 'dob' => {}, 'address' => {}, 'personal_address' => {}, 'verification' => {} }
          account.verification.fields_needed.each do |field|
            if field.match(/legal_entity/)
              field = field.gsub(/^legal_entity./, '')
              if field.match(/^.*\./)
                subfield = field.gsub(field.match(/^.*\./)[0], '')
                field    = field.match(/(^.*)\./)[1]
              end
              if subfield == 'document' && document
                file = Stripe::FileUpload.create(
                  {
                    purpose: 'identity_document',
                    file: document.photo.url
                  },
                  { stripe_account: account.id }
                )
                account.legal_entity.verification.document = file.id
              else
                account.legal_entity[field] =
                  case field
                  when 'type'
                    'individual'
                  when 'first_name'
                    self.user.first_name
                  when 'last_name'
                    self.user.last_name
                  when 'ssn_last_4'
                    self.ssn[-4..-1]
                  when 'personal_id_number'
                    self.ssn
                  when 'address'
                    { 'line1' => self.address1, 'line2' => self.address2, 'city' => self.city, 'state' => self.state, 'postal_code' => self.zip }
                  when 'personal_address'
                    { 'line1' => self.address1, 'line2' => self.address2, 'city' => self.city, 'state' => self.state, 'postal_code' => self.zip }
                  when 'dob'
                    { 'month' => self.dob[0..1], 'day' => self.dob[2..3], 'year' => self.dob[4..7] }
                  end
              end
            end
          end
          account.save
          self.update_attribute :verified, true unless account.verification.fields_needed[0]
        else
          true
        end
      rescue Stripe::InvalidRequestError
        false
      end
    else
      false
    end
  end

  def assign_market
    self.market = Market.near(self.zip, 50)[0]
  end

  private

  def fetch_zone
    if !zone && lng
      timezone = Timezone::Zone.new :latlon => [lat, lng]
      self.zone = timezone.zone
    end
  end

  def create_stripe_recipient
    unless stripe_recipient_id || !user
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
