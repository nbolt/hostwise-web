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
    property_1 = nil
    VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
    property_1.next_service_date.must_equal(Date.today + 1.day)
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
end