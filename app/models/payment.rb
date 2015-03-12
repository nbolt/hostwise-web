class Payment < ActiveRecord::Base
  belongs_to :user

  has_many :bookings, autosave: true

  as_enum :status, active: 1, deleted: 0, pending: 2

  before_create :set_card_type, :set_bank_name

  validates :fingerprint, uniqueness: true

  scope :active, -> { where(status_cd: 1) }

  def card?
    stripe_id.present?
  end

  def bank?
    balanced_id.present?
  end

  def display
    if card?
      "#{card_type.titleize} #{last4}"
    elsif bank?
      "Bank #{last4}"
    end
  end

  private

  def set_card_type
    self.card_type.gsub! '_', ' ' if card_type
  end

  def set_bank_name
    self.bank_name.downcase! if bank_name
  end
end
