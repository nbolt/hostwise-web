namespace :payouts do
  task process_outstanding: :environment do
    Payout.where(status_cd: 0).each do |payout|
      payout.process!
    end
  end
end
