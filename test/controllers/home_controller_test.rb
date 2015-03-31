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
    post :signup
    # assert_redirected_to :root    
  end

  it 'signin' do
    post :signin
    # assert_redirected_to :root  
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
  end

  it 'stripe_recipient' do
  end

  it 'user' do
  end
end