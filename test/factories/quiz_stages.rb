FactoryGirl.define do
  factory :quiz_stage_1, class: QuizStage do
  end

  factory :quiz_stage_2, class: QuizStage do
  	took_at 0
  end
end