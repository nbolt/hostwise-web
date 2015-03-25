require "test_helper"

describe Payment do
	it 'displays card properly' do
		visa_card = create(:visa_card)
		visa_card.display.must_equal 'Visa 1234'
	end
end
