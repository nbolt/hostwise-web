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
  end

  it 'should display property photos' do
  	property_1 = create(:property_1)
  	property_1.primary_photo.must_equal '/images/generic_property_with_circle.png'
  end
end