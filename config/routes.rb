Rails.application.routes.draw do

  get '/auth' => 'auth#auth', as: 'auth'
  get '/home' => 'home#home', as: 'home'

  post '/password_resets' => 'password_resets#create'
  get  '/password_resets/:id/edit' => 'password_resets#edit', as: :edit_password_reset
  put  '/password_resets/:id' => 'password_resets#update'

  scope module: 'host', constraints: { subdomain: 'host' } do
    get   '/' => 'home#index'
    get   '/pricing' => 'home#pricing', as: :host_pricing
    get   '/faq' => 'home#faq', as: :host_faq
    get   '/help' => 'home#help', as: :host_help
    get   '/properties/new'   => 'properties#new'
    get   '/properties/first' => 'properties#first'
    post  '/properties/address' => 'properties#address'
    post  '/properties/build' => 'properties#build'
    get   '/properties/:slug' => 'properties#show'
    post  '/properties/:slug' => 'properties#update'
    get   '/user/edit' => 'users#edit', as: :edit_host_user
    put   '/user/update' => 'users#update'
    match '/users/:action' => 'users', via: [:get, :post]
    match '/properties/:slug/:action' => 'properties', via: [:get, :post]
    match '/properties/:slug/:booking/:action' => 'bookings', via: [:get, :post]
  end

  get '/user' => 'home#user'
  get '/signin' => 'home#signin', as: :signin
  get '/signup' => 'home#signup', as: :signup
  get '/signout' => 'home#signout', as: :signout
  get '/pricing' => 'home#pricing', as: :pricing
  get '/faq' => 'home#faq', as: :faq

  match '/:action' => 'home', via: [:get, :post]
  match '/:controller/:action', via: [:get, :post]

  root to: 'home#index'
end
