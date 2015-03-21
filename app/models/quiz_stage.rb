class QuizStage < ActiveRecord::Base
  belongs_to :contractor_profile

  scope :passed, -> (contractor_profile) { where('contractor_profile_id = ? and pass = ?', contractor_profile.id, true).order('created_at DESC') }

  # next quiz will be taken at nth job (based on last quiz taken)
  # eg. if last quiz was taken at 2nd job, next quiz will be at 6th job
  def next
    case took_at
      when 0
        2
      else
        -1
    end
  end
end
