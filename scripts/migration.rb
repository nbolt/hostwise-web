require 'active_record'
require 'friendly_id'
require 'pg_search'
require 'simple_enum'
require 'pg'
require 'smartystreets'
require 'pry'

SmartyStreets.set_auth(ENV['STREETS_AUTH_ID'], ENV['STREETS_AUTH_TOKEN'])

class SecondDatabaseModel < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(
    :adapter  => 'postgresql',
    :database => ENV['OLD_DB'],
    :host     => 'localhost'
  )
end

class Place < SecondDatabaseModel
  belongs_to :porter_user
  #enum home_type: [:apt, :condo, :house]

  def full_address
    "#{address1}#{address2.present? ? ' ' + address2 : ''} #{city}, CA #{postal_code}"
  end
end

class PorterUser < SecondDatabaseModel
  self.table_name = 'users'
  has_many :places, dependent: :destroy
end


class Property < ActiveRecord::Base
  extend FriendlyId
  include PgSearch

  friendly_id :slug_candidates, use: :slugged

  #as_enum :rental_type, full_time: 0, part_time: 1
  #as_enum :property_type, house: 0, condo: 1

  belongs_to :user

  before_validation :standardize_address

  def nickname
    title || address1
  end

  private

  def standardize_address
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

  def slug_candidates
    [
      :nickname,
      [:nickname, :id]
    ]
  end
end

class User < ActiveRecord::Base
  has_many :properties, dependent: :destroy

  #as_enum :role, admin: 0, host: 1, contractor: 2
  #as_enum :status, trainee: 1, contractor: 2, trainer: 3
end



ActiveRecord::Base.establish_connection(
  :adapter  => 'postgresql',
  :database => ENV['NEW_DB'],
  :host     => 'localhost'
)

User.destroy_all
Property.destroy_all

PorterUser.all.each do |user|
  n = user.phone_number.match(/.*(\d).*(\d).*(\d).*(\d).*(\d).*(\d).*(\d).*(\d).*(\d).*(\d)/)
  if n && n[10]
    parsed_number = "#{n[1]}#{n[2]}#{n[3]}#{n[4]}#{n[5]}#{n[6]}#{n[7]}#{n[8]}#{n[9]}#{n[10]}"
  else
    parsed_number = ''
  end

  first_name = user.name.split(' ')[0]
  last_name  = user.name.split(' ')[1]

  User.create(
    email: user.email,
    phone_number: parsed_number,
    first_name: first_name,
    last_name: last_name,
    phone_confirmed: true,
    role_cd: 1,
    activation_state: 'active',
    crypted_password: '.',
    salt: '.'
  )
end

Place.all.each do |place|
  porter_user = PorterUser.where(id: place.user_id)[0]
  if porter_user
    if place.home_type == 2
      home_type = 0
    else
      home_type = 1
    end

    user = User.where(email: porter_user.email)[0]

    if place.details['bedrooms'] == 'studio'
      bedrooms = 0
    else
      bedrooms = place.details['bedrooms']
    end

    Property.create(
      address1: place.address1,
      address2: place.address2,
      city: place.city,
      zip: place.postal_code,
      user_id: user.id,
      property_type_cd: home_type,
      title: place.nickname,
      access_info: place.entry_infomation,
      trash_disposal: place.trash_disposal,
      additional_info: place.add_instruction,
      parking_info: '?',
      restocking_info: '?',
      bedrooms: bedrooms,
      bathrooms: place.details['bathrooms'],
      king_beds: place.details['beds']['king'],
      queen_beds: place.details['beds']['queen'],
      full_beds: place.details['beds']['full'],
      twin_beds: place.details['beds']['twin']
    )
  end
end