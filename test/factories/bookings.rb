FactoryGirl.define do |booking|
  factory :booking_cancelled, class: Booking do
    status_cd 2
    property
    after(:create) {|booking| booking.services << create(:cleaning)}
  end
end