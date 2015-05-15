namespace :migrate do
  task transactions: :environment do
    ids = Transaction.all.map(&:stripe_charge_id)
    ids = ids.select{|id| ids.count(id) > 1}.uniq
    ids.each do |id|
      transactions = Transaction.where(stripe_charge_id: id)
      rsp = Stripe::Charge.retrieve id
      new_transaction = Transaction.create(stripe_charge_id: id, amount: rsp.amount, status_cd: transactions.last.status_cd, failure_message: transactions.last.failure_message)
      new_transaction.update_attribute :charged_at, transactions.last.created_at
      transactions.each do |transaction|
        transaction.bookings.each do |booking|
          new_transaction.bookings << booking
        end
      end
      transactions.destroy_all
    end
  end
end
