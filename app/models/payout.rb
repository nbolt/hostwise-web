class Payout < ActiveRecord::Base
  belongs_to :user
  belongs_to :job

  as_enum :status, unprocessed: 0, pending: 1, completed: 2, failed: 3

  scope :unprocessed, -> { where(status_cd: 0) }
  scope :pending, -> { where(status_cd: 1) }

  def process!
    recipient = Stripe::Recipient.retrieve user.stripe_recipient_id

    if recipient.verified
      rsp = Stripe::Transfer.create(
        :amount => amount,
        :currency => "usd",
        :recipient => "rp_15gRNjGQgOKVfE1z0JNClJpk",
        :statement_descriptor => "HostWise Payout",
        :metadata => { payout_id: id },
        :card => user.payments.payout[0].stripe_id
      )
      case rsp.status
      when 'pending'
        self.update_attribute :status_cd, 1
      when 'paid'
        self.update_attribute :status_cd, 2
      else
        false
      end
    else
      false
    end
  end
end
