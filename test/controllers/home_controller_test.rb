require "test_helper"

describe HomeController do
  #  before(:each) do 
  #  user_name_11 = nil
  #  VCR.use_cassette('create_user_name_11') { user_name_11 = create(:user_name_11) }
  #  login_user(user_name_11)
  #  end

  it 'index' do
    get :index
  end

  it 'signup' do
    user_name_13 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    login_user(user_name_13)

    post :signup
    assert_redirected_to root_path  
  end

  it 'signin' do
    user_name_13 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    login_user(user_name_13)

    post :signin
    assert_redirected_to auth_path  
  end

  it 'signout' do
    post :signout
    assert_redirected_to :root
  end

  it 'pricing' do
    get :pricing
    must_render_template 'common/_pricing'
  end 

  it 'faq' do
    get :faq
    must_render_template 'common/_faq'
  end

  it 'cost' do
    get(:cost, {'param' => "value"} )  
    assert_response :success
    body = JSON.parse(response.body)
    body.must_equal JSON.parse(PRICING.to_json)
  end

  it 'man_hrs' do
    get(:man_hrs, {'param' => "value"} )  
    assert_response :success
    body = JSON.parse(response.body)
    body.must_equal JSON.parse(MAN_HRS.to_json)
  end

  it 'contact_email' do
    user_name_13 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    login_user(user_name_13)
  end

  it 'stripe_recipient' do
    get :stripe_recipient
    assert_response :success
    body = JSON.parse(response.body)
    body.must_equal ( {'success' => false} )

    user_name_13 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    login_user(user_name_13)
    get :stripe_recipient
    assert_response :success
    body = JSON.parse(response.body)
    body['recipient']['id'].must_equal 'acct_15p4IHCrporZAQeM' # not sure hardcoding this value is the best way to go about this...
  end

  it 'user' do
    get :user
    must_render_template nil

    user_name_13 = nil, user_name_10 = nil, user_name_11 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    VCR.use_cassette('create_user_name_11') { user_name_11 = create(:user_name_11) }
    VCR.use_cassette('create_user_name_10') { user_name_10 = create(:user_name_10) }
    
    login_user(user_name_13)
    get :user
    assert_response :success
    body = JSON.parse(response.body)
    body['user']['email'].must_equal 'dustinj593@gmail.com'

    logout_user
    login_user(user_name_10)
    get :user
    assert_response :success
    body = JSON.parse(response.body)
    body['user']['email'].must_equal 'dustinjones600@gmail.com'

    logout_user
    login_user(user_name_11)
    get :user
    assert_response :success
    body = JSON.parse(response.body)
    body['user']['email'].must_equal 'david.siqi.kong@gmail.com'
  end
end