class QuizStage < ActiveRecord::Base
  belongs_to :contractor_profile

  scope :last_taken, -> (contractor_profile) { where('contractor_profile_id = ? and pass = ?', contractor_profile.id, true).order('created_at DESC').first }

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
    end
  end
end
