require "test_helper"

describe DataController do
  it 'cities' do
    city_1 = nil, city_2 = nil
    VCR.use_cassette('create_city_1') { city_2 = create(:city_1) }
    VCR.use_cassette('create_city_2') { city_2 = create(:city_2) }

    get(:cities,:term => 'plano')  
    assert_response :success
    body = JSON.parse(response.body)
    body[0]['name'].must_equal 'plano'
  end 

  it 'services' do
    cleaning = create(:cleaning)
    linens = create(:linens)
    toiletries = create(:toiletries)
    pool = create(:pool)
    patio = create(:patio)
    windows = create(:windows)
    preset = create(:preset)

    get(:services, {'param' => "value"} )  
    assert_response :success
    body = JSON.parse(response.body)
    body[0]['name'].must_equal 'cleaning'
    body[1]['name'].must_equal 'linens'
    body[2]['name'].must_equal 'toiletries'
    body[3]['name'].must_equal 'pool'
    body[4]['name'].must_equal 'patio'
    body[5]['name'].must_equal 'windows'
    body[6]['name'].must_equal 'preset'
  end

  it 'properties' do
    user_name_14 = nil, property_1 = nil, property_2 = nil
    VCR.use_cassette('create_property_1') { property_1 = create(:property_1) }
    property_1.must_equal property_1
    VCR.use_cassette('create_property_2') { property_1 = create(:property_2) }
    property_2.must_equal property_2
    VCR.use_cassette('create_user_name_14') { user_name_14 = create(:user_name_14) }

    login_user(user_name_14)

    get(:properties, :term => '75093')
    assert_response :success
    body = JSON.parse(response.body)
    #body[0]['zip'].must_equal ''
  end

  it 'service_available' do
  end

  it 'payments' do
  end

  it 'jobs' do
    
  end

  it 'refresh_day' do
  end

  it 'transactions' do
  end

  it 'contractors' do
    user_name_6 = nil, user_name_8 = nil, profile_1 = nil, profile_2 = nil
    VCR.use_cassette('create_profile_1') { profile_1 = create(:profile_1) }
    profile_1.must_equal profile_1
    VCR.use_cassette('create_profile_2') { profile_2 = create(:profile_2) }
    profile_2.must_equal profile_2

    VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
    VCR.use_cassette('create_user_name_8') { user_name_8 = create(:user_name_8) }

    get(:contractors, term: 'dustinjones597')
    assert_response :success
    body = JSON.parse(response.body)
    body[0]['email'].must_equal 'dustinjones597@gmail.com'
  end

  it 'hosts' do
    user_name_12 = nil, user_name_13 = nil, profile_1 = nil, profile_2 = nil
    VCR.use_cassette('create_profile_1') { profile_1 = create(:profile_1) }
    profile_1.must_equal profile_1
    VCR.use_cassette('create_profile_2') { profile_2 = create(:profile_2) }
    profile_2.must_equal profile_2

    VCR.use_cassette('create_user_name_12') { user_name_12 = create(:user_name_12) }
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    get :hosts, term: 'claire'
    assert_response :success
    body = JSON.parse(response.body)
    body[0]['email'].must_equal 'claire.s.beaumont@gmail.com'
  end
end
