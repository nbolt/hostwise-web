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
    post  '/properties/upload' => 'properties#upload'
    get   '/properties/:slug' => 'properties#show'
    post  '/properties/:slug' => 'properties#update'
    get   '/user/edit' => 'users#edit'
    put   '/user/update' => 'users#update'
    post  '/user/deactivate' => 'users#deactivate'
    post  '/message' => 'users#message'
    get   '/payments' => 'payments#index'
    post  '/payments/add' => 'payments#add'
    put   '/payments/delete' => 'payments#delete'
    put   '/payments/default' => 'payments#default'
    post  '/payments/verify' => 'payments#verify'
    post  '/service_notifications/create' => 'service_notifications#create'
    get   '/notifications' => 'notifications#index'
    put   '/notifications/update' => 'notifications#update'
    get   '/transactions' => 'transactions#index'
    get   '/last_services' => 'users#last_services'
    match '/users/:action' => 'users', via: [:get, :post]
    match '/properties/:slug/:action' => 'properties', via: [:get, :post]
    match '/properties/:slug/:booking/:action' => 'bookings', via: [:get, :post]
  end

  scope module: 'contractor', constraints: { subdomain: 'contractor' } do
    get   '/' => 'home#index'
    get   '/faq' => 'home#faq', as: :contractor_faq
    get   '/help' => 'home#help', as: :contractor_help
    get   '/jobs' => 'jobs#index', as: :contractor_jobs
    get   '/jobs/:id' => 'jobs#show'
    match '/jobs/:id/:action' => 'jobs', via: [:get, :post]
    match  '/trainee/:action' => 'trainee', via: [:get, :post]
    get   '/user/edit' => 'users#edit'
    put   '/user/update' => 'users#update'
    post  '/user/deactivate' => 'users#deactivate'
    post  '/message' => 'users#message'
    get   '/users/:id/activate' => 'users#activate', as: :activate
    put   '/users/:id/activated' => 'users#activated'
    put   '/users/:id/avatar' => 'users#avatar'
    get   '/user/jobs_today' => 'users#jobs_today'
    get   '/payments' => 'payments#index'
    post  '/payments/add' => 'payments#add'
    put   '/payments/delete' => 'payments#delete'
    post  '/background_checks' => 'background_checks#create'
    get   '/availability' => 'availability#index'
    post  '/availability/add' => 'availability#add'
    get   '/notifications' => 'notifications#index'
    put   '/notifications/update' => 'notifications#update'
  end

  scope module: 'admin', constraints: { subdomain: 'admin' } do
    get   '/' => 'home#index'
    get   '/user/edit' => 'users#edit'
    put   '/user/update' => 'users#update'
    post  '/user/deactivate' => 'users#deactivate'
    get   '/contractors' => 'contractors#index'
    post  '/contractors/signup' => 'contractors#signup'
    get   '/contractors/:id/edit' => 'contractors#edit'
    put   '/contractors/:id/update' => 'contractors#update'
    post  '/contractors/:id/deactivate' => 'contractors#deactivate'
    post  '/contractors/:id/reactivate' => 'contractors#reactivate'
    get   '/hosts' => 'hosts#index'
    get   '/hosts/:id/edit' => 'hosts#edit'
    put   '/hosts/:id/update' => 'hosts#update'
    post  '/hosts/:id/deactivate' => 'hosts#deactivate'
    post  '/hosts/:id/reactivate' => 'hosts#reactivate'
    get   '/bookings' => 'bookings#index'
  end

  get '/user' => 'home#user'
  get '/signin' => 'home#signin', as: :signin
  get '/signup' => 'home#signup', as: :signup
  get '/signout' => 'home#signout', as: :signout
  get '/pricing' => 'home#pricing', as: :pricing
  get '/faq' => 'home#faq', as: :faq

  get '/cost' => 'home#cost'
  get '/about' => 'home#about', as: :about
  get '/contact' => 'home#contact', as: :contact
  get '/terms' => 'home#terms', as: :terms
  get '/privacy' => 'home#privacy', as: :privacy

  post '/notifications/background_check' => 'notifications#background_check', as: :background_check_notification
  post '/contact_email' => 'home#contact_email'

  match '/:action' => 'home', via: [:get, :post]
  match '/:controller/:action', via: [:get, :post]

  root to: 'home#index'
end
