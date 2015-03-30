require "test_helper"

describe QuizStage do 
	it 'next works properly' do
		quiz_stage_1 = create(:quiz_stage_1)
		quiz_stage_1.next.must_equal -1

		quiz_stage_2 = create(:quiz_stage_2)
		quiz_stage_2.next.must_equal 2
	end
end
