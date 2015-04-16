require "test_helper"

describe Property do
	it 'addresses correctly' do
    property_1 = nil; property_2 = nil

		VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
		property_1.short_address.must_equal '4408 Lone Tree Dr 75093'

		property_1.full_address.must_equal '4408 Lone Tree Dr, Plano, TX 75093'
		
		VCR.use_cassette('create_property_2') { property_2 = create(:property_2) }
		property_2.full_address.must_equal '4404 Lone Tree Dr # 4, Plano, TX 75093'
  end

  it 'chooses right next service date' do
    property_9 = nil, booking_tomorrow = nil
    VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
    VCR.use_cassette('create_booking_tomorrow') { booking_tomorrow = create(:booking_tomorrow) }
    booking_tomorrow.property.next_service_date.must_equal (Date.today + 1.day)
  end

  it 'chooses right last service date' do
    property_9 = nil, booking_yesterday = nil
    VCR.use_cassette('create_property_9') { property_9 = create(:property_9) }
    VCR.use_cassette('create_booking_yesterday') { booking_yesterday = create(:booking_yesterday) }
    booking_yesterday.property.last_service_date.must_equal (Date.today - 1.day)
  end

  it 'displays property size correctly' do
    property_1 = nil
  	VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
  	property_1.property_size.must_equal '2BD/2BA House'
  end

  it 'is invalid with invalid address' do
    property_6 = nil
    assert_raises ActiveRecord::RecordInvalid do 
      VCR.use_cassette('create_property_6') { property_6 = create(:property_6) }
    end
  end

  it 'should display property photos' do
    property_1 = nil; property_2 = nil
  	VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
  	property_1.primary_photo.must_equal '/images/generic_property_with_circle.png'

    VCR.use_cassette('create_property_2') { property_2 = create(:property_2) }
    property_2.primary_photo.must_equal nil
  end

  it 'displays neighborhood info properly' do
    property_1 = nil; property_8 = nil; property_3 = nil

    zip_1 = create(:zip_1)
    zip_1.code.must_equal zip_1.code # load zip

    VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
    property_1.neighborhood.must_equal 'Preston Meadow, Plano, 75093'

    zip_2 = create(:zip_2)
    zip_2.code.must_equal zip_2.code # load zip

    VCR.use_cassette('create_property_8') { property_8 = create(:property_8) }
    property_8.neighborhood.must_equal 'Los Angeles, 90023'

    VCR.use_cassette('create_property_3') { property_3 = create(:property_3) }
    property_3.neighborhood.must_equal ''
  end

  it 'can be self found' do
    property_1 = nil
    VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
    Property.find_by_slug(property_1.id).must_equal property_1
  end

  it 'can be searched correctly' do
    property_1 = nil; property_2 = nil; property_8 = nil
    
    VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
    property_1.must_equal property_1
    VCR.use_cassette('create_property_2') { property_2 = create(:property_2) }
    property_2.must_equal property_2
    VCR.use_cassette('create_property_8') { property_8 = create(:property_8) }
    property_8.must_equal property_8
    Property.search('4408 lone tree', 'alphabetical')[0].address1.must_equal property_1.address1
    Property.search('4408 lone tree', 'alphabetical')[0].address2.must_equal property_1.address2
  
    Property.search('plano', 'recently_added')[0].address1.must_equal property_2.address1
    Property.search('plano', 'recently_added')[0].address2.must_equal property_2.address2

    Property.search('3100', 'deactivated')[0].address1.must_equal property_8.address1

    Property.search('4408 lone tree')[0].address1.must_equal property_1.address1
    Property.search('4408 lone tree')[0].address2.must_equal property_1.address2
  
    Property.search('75093', 'upcoming_service')[0].address1.must_equal property_1.address1

    Property.search('ddg24422r34twdsv').must_equal []
  end

  it 'neighborhood_address' do
    property_1 = nil, zip_1 = nil, zip_2 = nil, property_8 = nil, property_10 = nil
    VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
    VCR.use_cassette('create_zip_1') { zip_1 = create(:zip_1) }
    zip_1.must_equal zip_1
    property_1.neighborhood_address.must_equal '4408 Lone Tree Dr, Preston Meadow, 75093'
 
    VCR.use_cassette('create_property_8') { property_8 = create(:property_8) }
    VCR.use_cassette('create_zip_2') { zip_2 = create(:zip_2) }
    zip_2.must_equal zip_2
    property_8.neighborhood_address.must_equal '3100 Wynwood Ln, Los Angeles, 90023'

    VCR.use_cassette('create_property_10') { property_10 = create(:property_10) }
    property_10.neighborhood_address.must_equal '2025 Wilshire Blvd, Santa Monica, 90403'
  end

  it 'king_bed_count' do
    property_5 = nil, property_8 = nil
    VCR.use_cassette('create_property_5') { property_5 = create(:property_5) }
    property_5.king_bed_count.must_equal 8

    VCR.use_cassette('create_property_8') { property_8 = create(:property_8) }
    property_8.king_bed_count.must_equal 2
  end

  it 'beds' do
    property_5 = nil, property_8 = nil
    VCR.use_cassette('create_property_5') { property_5 = create(:property_5) }
    property_5.beds.must_equal 9

    VCR.use_cassette('create_property_8') { property_8 = create(:property_8) }
    property_8.beds.must_equal 2
  end

  it 'display_phone_number' do
    property_11 = nil, property_8 = nil
    VCR.use_cassette('create_property_11') { property_11 = create(:property_11) }
    VCR.use_cassette('create_property_8') { property_8 = create(:property_8) }
    property_11.display_phone_number.must_equal '(214) 264-2230'
    property_8.display_phone_number.must_equal ''
  end
end