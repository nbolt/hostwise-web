FactoryGirl.define do
  factory :credit_card, class: Payment do
    last4 '4242'
    card_type 'Visa'
    status :active
  end

  factory :invalid_card, class: Payment do
  	last4 '0341'
  	card_type 'Visa'
  	status :active
  end

  factory :visa_card, class: Payment do
    last4 '1234'
    card_type 'Visa'
    status :active
  end

  factory :bank_account, class: Payment do
    last4 '2329'
    bank_name 'BANCORP'
    status :active
  end
end