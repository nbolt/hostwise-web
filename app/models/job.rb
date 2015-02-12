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
    if charge!
      completed!
      save
    else
      false
    end
  end

  private

  def charge!
    if booking.payment.stripe_id
      rsp = nil
      begin
        rsp = Stripe::Charge.create(
          amount: 100,
          currency: 'usd',
          customer: booking.property.user.stripe_customer_id,
          card: booking.payment.stripe_id,
          description: ' ',
          statement_descriptor: ' ',
          metadata: { job_id: id }
        )
        booking.transactions.create(stripe_charge_id: rsp.id, status_cd: 0)
        true
      rescue Stripe::CardError => e
        err  = e.json_body[:error]
        booking.transactions.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message])
        false
      end
    elsif booking.payment.balanced_id
      false
    else
      false
    end
  end
end
