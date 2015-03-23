require "test_helper"

describe Booking do
  it 'calculates cost correctly' do
    booking_cancelled = create(:booking_cancelled)
    booking_cancelled.cost.must_equal 25
  end

end