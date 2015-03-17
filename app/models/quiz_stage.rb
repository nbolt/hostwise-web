class QuizStage < ActiveRecord::Base
  belongs_to :contractor_profile

  scope :passed, -> (contractor_profile) { where('contractor_profile_id = ? and pass = ?', contractor_profile.id, true).order('created_at DESC') }

  # next quiz will be taken at nth job (based on last quiz taken)
  # eg. if last quiz was taken at 2nd job, next quiz will be at 6th job
  def next
    case took_at
      when 0
        1
      when 1
        2
      when 2
        6
      when 6
        11
      when 11
        21
      when 21
        41
      else
        0
    end
  end
end