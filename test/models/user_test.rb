require "test_helper"

describe User do
  it 'claims jobs correctly' do
    user_1 = nil; booking_1 = nil; booking_2 = nil; booking_3 = nil; booking_4 = nil
    VCR.use_cassette('create_user_1')    { user_1    = create(:user_1) }
    VCR.use_cassette('create_booking_1') { booking_1 = create(:booking_1) }
    VCR.use_cassette('create_booking_2') { booking_2 = create(:booking_2) }
    VCR.use_cassette('create_booking_3') { booking_3 = create(:booking_3) }
    VCR.use_cassette('create_booking_4') { booking_4 = create(:booking_4) }
    user_1.claim_job booking_1.job
    user_1.claim_job booking_2.job
    user_1.claim_job booking_3.job
    user_1.claim_job booking_4.job
    user_1.jobs.on_date(booking_1.job.date).count.must_equal 4
    user_1.jobs.on_date(booking_3.job.date).count.must_equal 4
    Booking.find(booking_1.id).timeslot.must_equal 16
    Booking.find(booking_2.id).timeslot.must_equal 11
    Booking.find(booking_3.id).timeslot.must_equal 11
    Booking.find(booking_4.id).timeslot.must_equal 14
  end
end