require "test_helper"

describe HomeController do
  it 'index' do
    get :index
  end

  it 'signup' do
  end

  it 'signin' do
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