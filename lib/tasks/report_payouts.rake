namespace :payouts do
  task report_outstanding: :environment do
    User.all.each do |user|
      if user.chain(:contractor_profile, :stripe_recipient_id)
        total = 0
        user.payouts.unprocessed.each {|payout| total += payout.amount}
        payouts = user.payouts.unprocessed.sort_by {|payout| payout.job.date}
        UserMailer.payday_report(user, payouts, payouts[0].job.date, payouts[-1].job.date).then(:deliver)
      end
    end
  end
end
