FactoryGirl.define do |job|
	factory :job_1, class: Job do
		association :booking, factory: :booking_cancelled
		date Date.new(2015, 4, 18)
  end

  factory :job_2, class: Job do
		association :booking, factory: :booking_active_1
		date Date.new(2015, 4, 18)
  end
end