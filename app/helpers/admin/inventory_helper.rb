module Admin::InventoryHelper
  def king_bed_count(jobs)
    jobs.select{|j| j.occasion_cd == 0}.reduce(0) {|acc, job| acc + (job.king_beds || 0)}
  end

  def twin_bed_count(jobs)
    jobs.select{|j| j.occasion_cd == 0}.reduce(0) {|acc, job| acc + (job.twin_beds || 0)}
  end

  def bed_count(jobs)
    jobs.reduce(0) {|acc, job| acc + (job.chain(:booking, :property, :beds) || 0)}
  end

  def toiletries(jobs)
    jobs.reduce(0) {|acc, job| acc + (job.toiletries || 0)}
  end

  def dirty_king_sheets(jobs)
    jobs.select{|j| j.occasion_cd == 1}.reduce(0) {|acc, job| acc + (job.king_beds || 0)}
  end

  def dirty_twin_sheets(jobs)
    jobs.select{|j| j.occasion_cd == 1}.reduce(0) {|acc, job| acc + (job.twin_beds || 0)}
  end

  def dirty_sheets(jobs)
    dirty_king_sheets(jobs) + dirty_twin_sheets(jobs)
  end
end