require 'test_helper'

describe Host::HomeController do
  it 'index' do

    user_name_9 = nil
    VCR.use_cassette('create_user_name_9') { user_name_9 = create(:user_name_9) }
    login_user(user_name_9)

    get :index

    assert_redirected_to properties_first_path
    
    #ogin_user(user_name_9)

    #get :index
    #must_render_template 'host/index'
  end

  it 'faq' do
    user_name_9 = nil
    VCR.use_cassette('create_user_name_9') { user_name_9 = create(:user_name_9) }
    
    login_user(user_name_9)

    get :faq
    must_render_template 'host/faq'
  end

  it 'pricing' do
    user_name_9 = nil
    VCR.use_cassette('create_user_name_9') { user_name_9 = create(:user_name_9) }
    
    login_user(user_name_9)

    get :pricing
    must_render_template 'host/pricing'
  end

  it 'contact' do
    user_name_9 = nil
    VCR.use_cassette('create_user_name_9') { user_name_9 = create(:user_name_9) }
    
    login_user(user_name_9)

    get :contact
    must_render_template "common/_contact"
  end
end