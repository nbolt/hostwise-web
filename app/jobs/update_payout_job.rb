class UpdatePayoutJob < ActiveJob::Base
  queue_as :default

  def perform(user, payouts)
    ActiveRecord::Base.connection_pool.with_connection do
      payouts = payouts.map {|id| Payout.find id}
      payouts.each do |payout|
        rsp = Stripe::Transfer.retrieve payout.stripe_transfer_id
        case rsp.status
        when 'pending'
          payout.update_attribute :status_cd, 1
        when 'paid'
          payout.update_attribute :status_cd, 2
        when 'failed'
          payout.update_attribute :status_cd, 3
        end
      end
      payouts = payouts.select{|payout| payout.status_cd == 2}.sort_by {|payout| payout.job.date}
      UserMailer.payday(user, payouts, payouts[0].job.date, payouts[-1].job.date).then(:deliver) unless payouts.empty?
    end
  end
end
