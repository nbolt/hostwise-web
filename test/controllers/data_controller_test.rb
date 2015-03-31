require "test_helper"

describe DataController do
  it 'cities' do
    city_1 = nil, city_2 = nil
    VCR.use_cassette('create_city_1') { city_2 = create(:city_1) }
    VCR.use_cassette('create_city_2') { city_2 = create(:city_2) }

    get(:cities, {'param' => "value"} )  
    assert_response :success
    body = JSON.parse(response.body)
    #body.must_equal 
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
  end

  it 'service_available' do
  end

  it 'payments' do
  end

  it 'jobs' do
    #get :jobs, scope: 'open'
    #assert_response :success
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
    # add users
    get :hosts, term: '593'
    assert_response :success
  end
end
