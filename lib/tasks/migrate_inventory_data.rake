namespace :migrate do
  task inventory_data: :environment do
    Job.distribution.dropoff.each do |job|
      standard_jobs = job.primary_contractor.jobs.standard.on_date(job.date)
      
      ['king_sheets', 'twin_sheets', 'pillow_count', 'bath_towels', 'hand_towels', 'face_towels', 'bath_mats'].each do |type|
        job.update_attribute type.to_sym, standard_jobs.reduce(0) {|acc, job|
          if job.checklist
            checklist_id = job.checklist.id
            settings = RailsSettings::SettingObject.where(var: 'inventory_count', target_id: checklist_id)[0]
            if settings.chain(:value, type)
              acc + settings.chain(:value, type)
            else
              acc
            end
          end
        }
      end
    
    end
  end
end
