require "test_helper"

describe Booking do
  it 'calculates cost correctly' do
    booking_cancelled = create(:booking_cancelled)
    booking_cancelled.cost.must_equal 25

    booking_active_1 = create(:booking_active_1)
    booking_active_1.cost.must_equal 130

    booking_active_2 = create(:booking_active_2)
    booking_active_2.cost.must_equal 75

    booking_active_3 = create(:booking_active_3)
    booking_active_3.cost.must_equal 220

    booking_late_next_day = create(:booking_late_next_day)
    booking_late_next_day.cost.must_equal 245

    booking_late_same_day = create(:booking_late_same_day)
    booking_late_same_day.cost.must_equal 245

    booking_first_booking_discount = create(:booking_first_booking_discount)
    booking_first_booking_discount.cost.must_equal 20
  end

  it 'charges correctly' do
  	booking_active_3 = create(:booking_active_3)
  	VCR.use_cassette('booking_charges') do
  		booking_active_3.charge!
  	end
  	booking_active_3.status.must_equal :completed
  end

  it 'formats date correctly' do
  	booking_date = create(:booking_dated)
  	booking_date.formatted_date.must_equal '03/23/2014'
  end

  it 'same day cancels correctly' do
  	booking_same_day_cancellation = create(:booking_lat_lng)
  	booking_same_day_cancellation.same_day_cancellation.must_equal false
  end

end