class Payment < ActiveRecord::Base
  belongs_to :user

  has_many :bookings, autosave: true

  as_enum :status, active: 1, deleted: 0, pending: 2

  before_create :set_card_type

  validates :fingerprint, uniqueness: true, allow_nil: true

  scope :active, -> { where(status_cd: 1) }
  scope :primary, -> { where(primary: true) }

  def display
    "#{card_type.titleize} #{last4}" if card_type.present?
  end

  def serializer_display
    display
  end

  private

  def set_card_type
    self.card_type.gsub! '_', ' ' if card_type
  end
end
