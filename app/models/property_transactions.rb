class PropertyTransactions < ActiveRecord::Base
  belongs_to :property
  belongs_to :stripe_transaction, class_name: 'Transaction'
end
