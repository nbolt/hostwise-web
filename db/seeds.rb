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

unless Zip.first
  CSV.foreach "#{Rails.root}/db/data/zips.csv" do |row|
    zip_code  = row[0]
    city      = row[1]
    county    = row[2]
    state     = row[3]
    state_id  = State.find_by_abbr!(state).id
    county_id = County.find_by_name_and_state_id!(county, state_id).id
    Zip.create_with(city_id: City.find_by_name_and_county_id!(city, county_id).id).find_or_create_by!(code: zip_code)
  end
end

unless Service.first
  Service.create(name: 'cleaning', display: 'Cleaning', extra: false)
  Service.create(name: 'linens', display: 'Linens & Towels', extra: false)
  Service.create(name: 'restocking', display: 'Restocking', extra: false)
  Service.create(name: 'pool', display: 'Pool Area', extra: true)
  Service.create(name: 'patio', display: 'Balcony / Patio', extra: true)
  Service.create(name: 'windows', display: 'Exterior Windows', extra: true)
end