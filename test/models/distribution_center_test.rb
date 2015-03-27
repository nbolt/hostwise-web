require "test_helper"

describe DistributionCenter do
	it 'should return the right neighborhood' do
		venice_center = nil; zip_3 = nil

		VCR.use_cassette('create_venice_center') { venice_center = create(:venice_center) }
		#VCR.use_cassette('create_plano_center') { venice_center = create(:plano_center) }
		VCR.use_cassette('create_zip_3') { zip_3 = create(:zip_3) }
		VCR.use_cassette('create_zip_1') { zip_1 = create(:zip_1) }

		no_zip = create(:no_zip)
		no_zip.neighborhood.must_equal ''

		zip_3.must_equal zip_3
		venice_center.neighborhood.must_equal 'Venice'

		# zip_1.must_equal zip_1
		# plano_center.neighborhood.must_equal 'Preston Meadow, Plano'

	end
end