Rails.application.routes.draw do
  default_url_options Rails.application.config.action_controller.default_url_options

  get '/auth' => 'auth#auth', as: 'auth'

  post '/password_resets' => 'password_resets#create'
  get  '/password_resets/:id/edit' => 'password_resets#edit', as: :edit_password_reset
  put  '/password_resets/:id' => 'password_resets#update'

  scope module: 'host', constraints: { subdomain: 'host' } do
    get   '/' => 'home#index'
    get   '/pricing' => 'home#pricing', as: :host_pricing
    get   '/faq' => 'home#faq', as: :host_faq
    get   '/contact' => 'home#contact', as: :host_contact
    get   '/properties/new'   => 'properties#new'
    get   '/properties/first' => 'properties#first'
    post  '/properties/address' => 'properties#address'
    post  '/properties/build' => 'properties#build'
    post  '/properties/upload' => 'properties#upload'
    get   '/properties/:slug' => 'properties#show', as: :property
    post  '/properties/:slug' => 'properties#update'
    get   '/user/edit' => 'users#edit'
    put   '/user/update' => 'users#update'
    post  '/user/deactivate' => 'users#deactivate'
    get   '/payments' => 'payments#index'
    post  '/payments/add' => 'payments#add'
    post  '/payments/:action/:id' => 'payments'
    post  '/service_notifications/create' => 'service_notifications#create'
    get   '/notifications' => 'notifications#index'
    put   '/notifications/update' => 'notifications#update'
    get   '/transactions' => 'transactions#index'
    get   '/transactions/:id' => 'transactions#show'
    get   '/last_services' => 'users#last_services'
    post  '/bookings/apply_discount' => 'bookings#apply_discount'
    match '/users/:action' => 'users', via: [:get, :post]
    match '/properties/:slug/:action' => 'properties', via: [:get, :post]
    match '/properties/:slug/:booking/:action' => 'bookings', via: [:get, :post]
  end

  scope module: 'contractor', constraints: { subdomain: 'contractor' } do
    get   '/' => 'home#index', as: :contractor_schedule
    get   '/contact' => 'home#contact', as: :contractor_contact
    get   '/jobs' => 'jobs#index', as: :contractor_jobs
    get   '/jobs/:id' => 'jobs#show', as: :job_details
    match '/jobs/:id/:action' => 'jobs', via: [:get, :post]
    match '/trainee/:action' => 'trainee', via: [:get, :post]
    get   '/user/edit' => 'users#edit'
    put   '/user/update' => 'users#update'
    post  '/user/deactivate' => 'users#deactivate'
    get   '/users/:id/activate' => 'users#activate', as: :activate
    get   '/users/activate' => 'users#activate'
    put   '/users/:id/activated' => 'users#activated'
    put   '/users/:id/avatar' => 'users#avatar'
    get   '/user/jobs_today' => 'users#jobs_today'
    get   '/payments' => 'payments#index'
    post  '/payments/add' => 'payments#add'
    post  '/payments/remove' => 'payments#remove'
    post  '/payments/:action/:id' => 'payments'
    #post  '/docusign/send' => 'docusign#create'
    get   '/availability' => 'availability#index'
    post  '/availability/add' => 'availability#add'
    get   '/notifications' => 'notifications#index'
    put   '/notifications/update' => 'notifications#update'
    get   '/quiz' => 'quiz#index'
    post  '/quiz/report' => 'quiz#report'
    get   '/quiz/type' => 'quiz#type'
    post  '/checklist' => 'jobs#checklist'
    post  '/checklist/update' => 'jobs#checklist_update'
    post  '/checklist/:action' => 'jobs'
  end

  scope module: 'admin', constraints: { subdomain: 'admin' } do
    get   '/' => 'home#index'
    get   '/user/edit' => 'users#edit'
    put   '/user/update' => 'users#update'
    post  '/user/deactivate' => 'users#deactivate'
    get   '/contractors' => 'contractors#index'
    post  '/contractors/signup' => 'contractors#signup'
    get   '/contractors/:id/edit' => 'contractors#edit'
    get   '/contractors/:id/notes' => 'contractors#notes'
    post  '/contractors/:id/new_note' => 'contractors#new_note'
    put   '/contractors/:id/update' => 'contractors#update'
    post  '/contractors/:id/deactivate' => 'contractors#deactivate'
    post  '/contractors/:id/reactivate' => 'contractors#reactivate'
    post  '/contractors/:id/delete' => 'contractors#delete'
    post  '/contractors/:id/complete_contract' => 'contractors#complete_contract'
    post  '/contractors/:id/background_check' => 'contractors#background_check'
    get   '/hosts' => 'hosts#index'
    get   '/hosts/:id/edit' => 'hosts#edit'
    get   '/hosts/:id/notes' => 'hosts#notes'
    post  '/hosts/:id/new_note' => 'hosts#new_note'
    put   '/hosts/:id/update' => 'hosts#update'
    post  '/hosts/:id/deactivate' => 'hosts#deactivate'
    post  '/hosts/:id/reactivate' => 'hosts#reactivate'
    get   '/inventory' => 'inventory#index'
    post  '/inventory/:action' => 'inventory'
    get   '/bookings' => 'bookings#index'
    match '/bookings/:id/:action' => 'bookings', via: [:get, :post]
    get   '/jobs' => 'jobs#index'
    get   '/jobs/:id' => 'jobs#show', as: :admin_job
    match '/jobs/:id/:action' => 'jobs', via: [:get, :post]
    get   '/properties' => 'properties#index'
    get   '/properties/:id' => 'properties#show'
    post  '/properties/:id' => 'properties#update'
    match '/properties/:id/:action' => 'properties', via: [:get, :post]
    get   '/transactions' => 'transactions#index'
    post  '/transactions/:action' => 'transactions'
    get   '/coupons' => 'coupons#index'
    post  '/coupons/:action' => 'coupons'
    post  '/coupons/:id/:action' => 'coupons'
    post  '/jobs/:action' => 'jobs'
    get   '/dashboard' => 'dashboard#index'
    match '/dashboard/:action' => 'dashboard', via: [:get, :post]
    get   '/login_as/:id' => 'auth#login_as'
  end

  get '/man_hrs' => 'home#man_hrs'
  get '/cost' => 'home#cost'
  get '/user' => 'home#user'
  get '/signin' => 'home#signin', as: :signin, constraints: {subdomain: 'www'}
  get '/signup' => 'home#signup', as: :signup, constraints: {subdomain: 'www'}
  get '/signout' => 'home#signout', as: :signout
  get '/pricing' => 'home#pricing', as: :pricing
  get '/faq' => 'home#faq', as: :faq
  get '/about' => 'home#about', as: :about, constraints: {subdomain: 'www'}
  get '/contact' => 'home#contact', as: :contact
  get '/terms' => 'home#terms', as: :terms
  get '/privacy' => 'home#privacy', as: :privacy

  post '/notifications/checkr' => 'notifications#checkr', as: :checkr_notification
  #post 'notifications/docusign' => 'notifications#docusign'
  post '/contact_email' => 'home#contact_email'

  match '/:action' => 'home', via: [:get, :post]
  match '/:controller/:action', via: [:get, :post]

  root to: 'home#index'
end
