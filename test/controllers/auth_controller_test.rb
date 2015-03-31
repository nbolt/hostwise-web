require 'test_helper'

describe AuthController do
  it 'auth' do
    get :auth
    assert_redirected_to '/signin'
  end
end