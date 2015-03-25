FactoryGirl.define do
  factory :transaction_1, class: Transaction do
  	amount 53136
  end

  factory :transaction_2, class: Transaction do
  	amount 24656
  end

  factory :transaction_3, class: Transaction do
  	amount 90000
  end
end