namespace :jobs do
  task process_outstanding: :environment do
    Job.not_complete.where('bookings.date < ?', Date.today).includes(:booking).references(:booking).each do |job|
      job.past_due!
      job.save
    end
  end
end
