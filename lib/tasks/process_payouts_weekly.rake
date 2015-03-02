namespace :payouts do
  task process_outstanding_weekly: :environment do
    if Time.now.wednesday?
      Payout.where(status_cd: 0).each do |payout|
        payout.process!
      end
    end
  end
end
