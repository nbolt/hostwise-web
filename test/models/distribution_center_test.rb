require "test_helper"

describe DistributionCenter do
	it 'should return the right neighborhood' do
		venice_center = nil; zip_3 = nil, city_center = nil, plano_center = nil

		VCR.use_cassette('create_venice_center') { venice_center = create(:venice_center) }
		VCR.use_cassette('create_city_center') { city_center = create(:city_center) }
		VCR.use_cassette('create_plano_center') { plano_center = create(:plano_center) }
		VCR.use_cassette('create_zip_3') { zip_3 = create(:zip_3) }
		VCR.use_cassette('create_zip_1') { zip_1 = create(:zip_1) }

		no_zip = create(:no_zip)
		no_zip.neighborhood.must_equal ''
		venice_center.neighborhood.must_equal 'Venice'
		zip_3.must_equal zip_3
		plano_center.neighborhood.must_equal 'Preston Meadow, Plano'

		venice_center.short_address.must_equal '1020 Lake St 90291'
		venice_center.full_address.must_equal	'1020 Lake St # 9, Venice, CA 90291' 
		city_center.full_address.must_equal '3430 S LA Brea Ave, Los Angeles, CA 90016'
	end

	it 'should error on invalid address' do
		invalid_center = nil
		VCR.use_cassette('create_invalid_center') { invalid_center = create(:invalid_center) }
	end
end