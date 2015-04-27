module Admin::InventoryHelper
  def king_bed_count(jobs)
    king_bed_count = 0
    jobs.each do |job|
      if job.king_beds != nil
        king_bed_count += job.king_beds 
      end
    end
    king_bed_count
  end

  def twin_bed_count(jobs)
    twin_bed_count = 0
    jobs.each do |job|
      if job.twin_beds != nil
        twin_bed_count += job.twin_beds 
      end
    end
    twin_bed_count
  end

  def bed_count(jobs)
    bed_count = 0
    jobs.each do |job|
      if job.king_beds != nil
        bed_count += job.king_beds
      end
      if job.twin_beds != nil
        bed_count += job.twin_beds
      end
      if job.queen_beds != nil
        bed_count += job.queen_beds
      end
      if job.full_beds != nil
        bed_count += job.full_beds
      end
    end
    bed_count
  end

  def toiletries(jobs)
    jobs.reduce(0) {|acc, job| acc + (if job.toiletries != nil then job.toiletries else 0 end)}
  end

  def dirty_king_sheets(jobs)
    jobs.reduce(0) {|acc, job| acc + (if job.king_sheets != nil then job.king_sheets else 0 end)}
  end

  def dirty_twin_sheets(jobs)
    jobs.reduce(0) {|acc, job| acc + (if job.twin_sheets != nil then job.twin_sheets else 0 end)}
  end

  def dirty_sheets(jobs)
    jobs.reduce(0) {|acc, job| acc + (if job.king_sheets != nil then job.king_sheets else 0 end) + (if job.twin_sheets != nil then job.twin_sheets else 0 end)}
  end
end