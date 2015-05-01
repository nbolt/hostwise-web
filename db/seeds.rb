unless State.first
  CSV.foreach("#{Rails.root}/db/data/states.csv") do |row|
    state_code = row[0]
    state_name = row[1]
    State.create_with(name: state_name).find_or_create_by!(abbr: state_code)
  end
end

unless County.first
  CSV.foreach("#{Rails.root}/db/data/counties.csv") do |row|
    state_code  = row[0]
    county_name = row[1]
    County.find_or_create_by!(state_id: State.find_by_abbr(state_code).id, name: county_name)
  end
end

unless City.first
  CSV.foreach("#{Rails.root}/db/data/cities.csv") do |row|
    state_two_digit_code = row[0]
    state_id = State.find_by_abbr!(state_two_digit_code).id

    county_name = row[1]
    city_name   = row[2]
    county      = County.find_by_state_id_and_name!(state_id, county_name)
    City.find_or_create_by!(county_id: county.id, name: city_name)
  end
end

unless ZipCode.first
  CSV.foreach "#{Rails.root}/db/data/zips.csv" do |row|
    zip_code  = row[0]
    city      = row[1]
    county    = row[2]
    state     = row[3]
    state_id  = State.find_by_abbr!(state).id
    county_id = County.find_by_name_and_state_id!(county, state_id).id
    ZipCode.create_with(city_id: City.find_by_name_and_county_id!(city, county_id).id).find_or_create_by!(code: zip_code)
  end
end

CSV.foreach "#{Rails.root}/db/data/service_zips.csv" do |row|
  code = row[0]
  zip  = ZipCode.where(code: code)[0]
  zip.update_attribute :serviced, true unless zip.serviced
end

CSV.foreach "#{Rails.root}/db/data/neighborhoods.csv" do |row|
  name = row[0]
  zips = row[1..-1]
  neighborhood = Neighborhood.find_or_create_by(name: name)
  zips.each do |z|
    zip = ZipCode.find_or_create_by(code: z)
    if neighborhood.zips.where(code: z).empty?
      zip.neighborhood = neighborhood
      zip.save
    end
  end
end

DistributionCenter.create(name: 'Venice Warehouse', address1:'1020 Lake St',address2:'#9',city:'Los Angeles',state:'CA',zip:'90291') unless DistributionCenter.where(address1:'1020 Lake St')[0]
DistributionCenter.create(name: 'Mid-City Warehouse', address1:'3430 South La Brea Avenue',city:'Los Angeles',state:'CA',zip:'90016') unless DistributionCenter.where(address1:'3430 S LA Brea Ave')[0]

Service.find_or_create_by(name: 'cleaning', display: 'Cleaning', extra: false)
Service.find_or_create_by(name: 'linens', display: 'Linens & Towels', extra: false)
Service.find_or_create_by(name: 'toiletries', display: 'Toiletries', extra: false)
Service.find_or_create_by(name: 'pool', display: 'Pool Area', extra: true)
Service.find_or_create_by(name: 'patio', display: 'Balcony / Patio', extra: true)
Service.find_or_create_by(name: 'windows', display: 'Exterior Windows', extra: true)
Service.find_or_create_by(name: 'preset', display: 'Staging', hidden: true)
