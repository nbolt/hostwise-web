Rails.application.routes.draw do

  get '/auth' => 'auth#auth', as: 'auth'

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
    get   '/user/edit' => 'users#edit'
    put   '/user/update' => 'users#update'
    post  '/message' => 'users#message'
    get   '/payments' => 'payments#index', as: :payments
    post  '/payments/add' => 'payments#add'
    put   '/payments/delete' => 'payments#delete'
    match '/users/:action' => 'users', via: [:get, :post]
    match '/properties/:slug/:action' => 'properties', via: [:get, :post]
    match '/properties/:slug/:booking/:action' => 'bookings', via: [:get, :post]
  end

  scope module: 'admin', constraints: { subdomain: 'admin' } do
    get   '/' => 'home#index'
    get   '/user/edit' => 'users#edit'
    put   '/user/update' => 'users#update'
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
