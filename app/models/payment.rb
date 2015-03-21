class Payment < ActiveRecord::Base
  belongs_to :user

  has_many :bookings, autosave: true

  as_enum :status, active: 1, deleted: 0, pending: 2

  before_create :set_card_type

  validates :fingerprint, uniqueness: true

  scope :active, -> { where(status_cd: 1) }

  def display
    if card?
      "#{card_type.titleize} #{last4}"
    end
  end

  private

  def set_card_type
    self.card_type.gsub! '_', ' ' if card_type
  end
end
