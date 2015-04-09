class BookingTransactions < ActiveRecord::Base
  belongs_to :booking
  belongs_to :stripe_transaction, class_name: 'Transaction'
end
