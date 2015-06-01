require "test_helper"

describe User do
  it 'claims jobs correctly' do
    user_1 = nil; user_2 = nil; booking_1 = nil; booking_2 = nil; booking_3 = nil; booking_4 = nil; booking_5 = nil
    VCR.use_cassette('create_user_1')    { user_1    = create(:user_1) }
    VCR.use_cassette('create_user_2')    { user_2    = create(:user_2) }
    VCR.use_cassette('create_booking_1') { booking_1 = create(:booking_1) }
    VCR.use_cassette('create_booking_2') { booking_2 = create(:booking_2) }
    VCR.use_cassette('create_booking_3') { booking_3 = create(:booking_3) }
    VCR.use_cassette('create_booking_4') { booking_4 = create(:booking_4) }
    VCR.use_cassette('create_booking_5') { booking_5 = create(:booking_5) }
    
    user_1.claim_job booking_1.job
    user_1.claim_job booking_2.job
    user_1.drop_job  booking_2.job
    user_1.claim_job booking_2.job
    user_1.claim_job booking_3.job
    user_1.claim_job booking_4.job
    user_1.drop_job  booking_4.job
    user_1.claim_job booking_4.job
    user_1.claim_job booking_5.job, true

    user_2.claim_job booking_2.job
    user_2.drop_job  booking_2.job
    user_2.claim_job booking_2.job
    user_2.claim_job booking_4.job
    
    user_1.jobs.on_date(booking_1.job.date).count.must_equal 5
    user_1.jobs.on_date(booking_3.job.date).count.must_equal 4
    user_2.jobs.on_date(booking_2.job.date).count.must_equal 1
    user_2.jobs.on_date(booking_4.job.date).count.must_equal 1
    
    Booking.find(booking_1.id).timeslot.must_equal 14
    Booking.find(booking_2.id).timeslot.must_equal 11
    Booking.find(booking_3.id).timeslot.must_equal 14
    Booking.find(booking_4.id).timeslot.must_equal 11
    Booking.find(booking_5.id).timeslot.must_equal 16
  end
end