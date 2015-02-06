class Payment < ActiveRecord::Base
  belongs_to :user

  has_many :bookings, autosave: true

  as_enum :status, active: 1, deleted: 0

  before_create :set_status, :set_card_type

  validates :fingerprint, uniqueness: true

  scope :active, -> { where(status_cd: 1) }

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

  def set_card_type
    self.card_type.gsub! '_', ' '
  end
end
