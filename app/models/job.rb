class Job < ActiveRecord::Base
  belongs_to :booking
  has_many :contractor_jobs, class_name: 'ContractorJobs'
  has_many :contractors, through: :contractor_jobs, source: :user

  as_enum :status, open: 0, scheduled: 1, in_progress: 2, completed: 3

  def self.open contractor
    Job.includes(:contractor_jobs).references(:contractor_jobs).where(status_cd: 0).where('contractor_jobs.user_id is null or contractor_jobs.user_id != ?', contractor.id)
  end

  def self.upcoming contractor
    Job.includes(:contractor_jobs).references(:contractor_jobs).where(status_cd: [0, 1]).where('contractor_jobs.user_id = ?', contractor.id)
  end

  def self.past contractor
    Job.includes(:contractor_jobs).references(:contractor_jobs).where(status_cd: 3).where('contractor_jobs.user_id = ?', contractor.id)
  end

  def size
    booking.services.count
  end

  def start!
    in_progress!
    save
  end

  def complete!
    completed!
    charge!
    save
  end

  private

  def charge!
    if booking.payment.stripe_id
      begin
        rsp = Stripe::Charge.create(
          amount: booking.cost * 100,
          currency: 'usd',
          customer: booking.property.user.stripe_customer_id,
          card: booking.payment.stripe_id,
          statement_descriptor: "HostWise #{id}"[0..21], # 22 characters max
          metadata: { job_id: id }
        )
        booking.transactions.create(stripe_charge_id: rsp.id, status_cd: 0, amount: booking.cost * 100)
        true
      rescue Stripe::CardError => e
        err  = e.json_body[:error]
        booking.transactions.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message], amount: booking.cost * 100)
        false
      end
    elsif booking.payment.balanced_id
      verification = Balanced::BankAccountVerification.fetch("/verifications/#{booking.payment.balanced_verification_id}")
      if verification.verification_status == 'pending'
        false
      else
        bank_account = Balanced::BankAccount.fetch("/bank_accounts/#{booking.payment.balanced_id}")
        order = Balanced::Order.fetch("/orders/#{booking.balanced_order_id}")
        rsp = order.debit_from(
          source: bank_account,
          amount: booking.cost * 100
        )
        booking.transactions.create(balanced_charge_id: rsp.id, status_cd: 2, amount: booking.cost * 100)
        true
      end
    else
      false
    end
  end
end
