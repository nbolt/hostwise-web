class ContractorProfileSerializer < ActiveModel::Serializer
  attributes :address1, :address2, :city, :country, :current_position, :dob, :docusign_completed, :driver_license,
             :emergency_contact_first_name, :emergency_contact_last_name, :emergency_contact_phone, :lat, :lng,
             :position, :position_cd, :ssn, :state, :test_session_completed, :user_id, :zip, :zone, :market_hash, :document

  has_one :market
end
