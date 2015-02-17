class Transaction < ActiveRecord::Base
  belongs_to :booking
  as_enum :status, successful: 0, failed: 1, pending: 2

  def self.completed user
    Transaction.where(status_cd: 0).includes({booking: [{property: :user}]}).references(:user).where('users.id = ?', user.id)
  end
end
