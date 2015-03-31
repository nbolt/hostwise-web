require "test_helper"
 
describe Admin::JobsController do
  it 'booking_cost' do
    booking_canceled = nil
    VCR.use_cassette('create_booking_cancelled') { booking_cancelled = create(:booking_cancelled) }
  end
end