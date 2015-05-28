FactoryGirl.define do |job|
  factory :job_1, class: Job do
    date Date.new(2016, 4, 18)
    status_cd 0
    size 1
    association :booking, factory: :booking_1
  end

  factory :job_2, class: Job do
    date Date.new(2016, 4, 18)
    status_cd 0
    size 2
    association :booking, factory: :booking_2
  end

  factory :job_3, class: Job do
    date Date.new(2016, 4, 19)
    status_cd 0
    size 1
    association :booking, factory: :booking_3
  end

  factory :job_4, class: Job do
    date Date.new(2016, 4, 19)
    status_cd 0
    size 2
    association :booking, factory: :booking_4
  end
end