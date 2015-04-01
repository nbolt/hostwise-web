namespace :payouts do
  task process_outstanding_weekly: :environment do
    if Date.today.wednesday?
      User.all.each do |user|
        if user.chain(:contractor_profile, :stripe_recipient_id)
          total = 0

          user.payouts.pending.each do |payout|
            rsp = Stripe::Transfer.retrieve payout.stripe_transfer_id
            case rsp.status
            when 'paid'
              payout.update_attribute :status_cd, 2
            when 'failed'
              payout.update_attribute :status_cd, 3
            end
          end

          user.payouts = user.payouts.order(:created_at)
          user.payouts.unprocessed.each do |payout|
            total += payout.amount
          end

          recipient = Stripe::Account.retrieve user.contractor_profile.stripe_recipient_id

          if recipient.verified
            rsp = Stripe::Transfer.create(
              :amount => total,
              :currency => 'usd',
              :destination => recipient.id,
              :statement_descriptor => 'HostWise Payout',
              :metadata => { payout_ids: user.payouts.unprocessed.map(&:id) }
            )

            case rsp.status
            when 'pending'
              user.payouts.unprocessed.each {|payout| payout.update_attributes(status_cd: 1, stripe_transfer_id: rsp.id)}
            when 'paid'
              user.payouts.unprocessed.each {|payout| payout.update_attributes(status_cd: 2, stripe_transfer_id: rsp.id)}
            when 'failed'
              user.payouts.unprocessed.each {|payout| payout.update_attributes(status_cd: 3, stripe_transfer_id: rsp.id)}
            else
              false
            end
          else
            false
          end
        end
      end
    end
  end
end
