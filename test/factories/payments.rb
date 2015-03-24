FactoryGirl.define do |booking|
  factory :credit_card, class: Payment do
    last4 '4242'
    card_type 'Visa'
    status :active
  end
end