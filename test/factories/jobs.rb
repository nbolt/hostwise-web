FactoryGirl.define do |job|
	factory :job_1, class: Job do
		association :booking, factory: :booking_cancelled
		date Date.new(2015, 4, 18)
  end
end