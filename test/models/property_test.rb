require "test_helper"

describe Property do
	it 'addresses correctly' do
		property_1 = create(:property_1)
		property_1.short_address.must_equal '4408 Lone Tree Dr 75093'

		property_1.full_address.must_equal '4408 Lone Tree Dr, Plano, TX 75093'
		
		property_2 = create(:property_2)
		property_2.full_address.must_equal '4404 Lone Tree Dr 4402 Lone Tree Dr., Plano, TX 75093'
  end

  it 'displays property size correctly' do
  	property_1 = create(:property_1)
  	property_1.property_size.must_equal '2BD/2BA House'
  end

  it 'is invalid with invalid address' do
    assert_raises ActiveRecord::RecordInvalid do 
      property_6 = create(:property_6)
    end
  end

  it 'should display property photos' do
  	property_1 = create(:property_1)
  	property_1.primary_photo.must_equal '/images/generic_property_with_circle.png'
  end

  it 'can be found by slug' do

  end

  it 'displays neighborhood info properly' do
    zip_1 = create(:zip_1)
    zip_1.code.must_equal zip_1.code # load zip

    property_1 = create(:property_1)
    property_1.neighborhood.must_equal 'Preston Meadow, Plano, 75093'

    zip_2 = create(:zip_2)
    zip_2.code.must_equal zip_2.code # load zip

    property_8 = create(:property_8)
    #property_8.neighborhood.must_equal 'los angeles 90023'
  end

  it 'can be self found' do
    property_1 = create(:property_1)
    Property.find_by_slug(property_1.id).must_equal property_1
  end
end