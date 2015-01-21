class Payment < ActiveRecord::Base
  belongs_to :user

  has_many :bookings, autosave: true

  as_enum :status, active: 1, deleted: 0

  before_create :set_status

  validates :fingerprint, uniqueness: true

  def card?
    stripe_id.present?
  end

  def bank?
    balanced_id.present?
  end

  private

  def set_status
    self.status = :active
  end
end
