FactoryGirl.define do |booking|
 factory :booking_1, class: Booking do
    date Date.new(2016, 4, 18)
    status_cd 1
    timeslot_type 1
    timeslot 16
    linen_handling_cd 1
    association :property, factory: :property_1
    after(:create) do |booking|
      booking.services << create(:cleaning)
      booking.services << create(:linens)
      booking.services << create(:pool)
      booking.update_cost!
      create(:job_1, booking: booking)
    end
  end

  factory :booking_2, class: Booking do
    date Date.new(2016, 4, 18)
    status_cd 1
    linen_handling_cd 1
    timeslot_type 0
    association :property, factory: :property_2
    after(:create) do |booking|
      booking.services << create(:cleaning)
      booking.services << create(:linens)
      booking.services << create(:pool)
      booking.update_cost!
      create(:job_2, booking: booking)
    end
  end

  factory :booking_3, class: Booking do
    date Date.new(2016, 4, 19)
    status_cd 1
    linen_handling_cd 1
    timeslot_type 0
    association :property, factory: :property_2
    after(:create) do |booking|
      booking.services << create(:cleaning)
      booking.services << create(:linens)
      booking.services << create(:pool)
      booking.update_cost!
      create(:job_3, booking: booking)
    end
  end

  factory :booking_4, class: Booking do
    date Date.new(2016, 4, 19)
    status_cd 1
    linen_handling_cd 1
    timeslot_type 0
    association :property, factory: :property_2
    after(:create) do |booking|
      booking.services << create(:cleaning)
      booking.services << create(:linens)
      booking.services << create(:pool)
      booking.update_cost!
      create(:job_4, booking: booking)
    end
  end
end