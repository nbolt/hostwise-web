class Transaction < ActiveRecord::Base
  has_many :booking_transactions, class_name: 'BookingTransactions', dependent: :destroy, foreign_key: :stripe_transaction_id
  has_many :bookings, through: :booking_transactions
  has_many :property_transactions, class_name: 'PropertyTransactions', dependent: :destroy, foreign_key: :stripe_transaction_id
  has_many :properties, through: :property_transactions

  as_enum :status, successful: 0, failed: 1, pending: 2
  as_enum :transaction_type, standard: 0, manual: 1, linen_recovery: 2

  before_create :set_charged_at

  scope :manual_charges, -> { where(status_cd: 0, transaction_type_cd: 1) }
  scope :on_month, -> (date) { where('extract(month from transactions.charged_at) = ? and extract(year from transactions.charged_at) = ?', date.month, date.year) }

  def self.completed(user, start_date, end_date)
    if start_date.present? && end_date.present?
      Transaction.where(status_cd: 0).where('bookings.date >= ? and bookings.date <= ?', DateTime.strptime(start_date, '%m/%d/%Y'), DateTime.strptime(end_date, '%m/%d/%Y')).includes({bookings: [{property: :user}]}).references(:user, :bookings).where('users.id = ?', user.id)
    else
      Transaction.where(status_cd: 0).includes({bookings: [{property: :user}]}).references(:user).where('users.id = ?', user.id)
    end
  end

  private

  def set_charged_at
    self.charged_at = Date.today
  end
end
