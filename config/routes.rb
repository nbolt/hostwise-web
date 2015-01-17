Rails.application.routes.draw do
  get '' => 'admin#index',   constraints: { subdomain: 'admin' }
  get '/:action' => 'admin', constraints: { subdomain: 'admin' }
  scope module: 'admin' do
    match '/auth/:action' => 'auth', via: [:get, :post], constraints: { subdomain: 'admin' }
  end

  get '' => 'contractor#index',   constraints: { subdomain: 'contractor' }
  get '/:action' => 'contractor', constraints: { subdomain: 'contractor' }
  scope module: 'contractor' do
    match '/auth/:action' => 'auth', via: [:get, :post], constraints: { subdomain: 'contractor' }
  end

  get   '/properties/new'   => 'properties#new'
  post  '/properties/build' => 'properties#build'
  get   '/properties/:slug' => 'properties#show'
  post  '/properties/:slug' => 'properties#update'
  match '/properties/:slug/:action' => 'properties', via: [:get, :post]

  post '/password_resets' => 'password_resets#create'
  get '/password_resets/:id/edit' => 'password_resets#edit', as: :edit_password_reset
  put '/password_resets/:id' => 'password_resets#update'

  get '/signin' => 'home#signin', as: :signin
  get '/signup' => 'home#signup', as: :signup
  get '/signout' => 'home#signout', as: :signout
  get '/pricing' => 'home#pricing', as: :pricing
  get '/faq' => 'home#faq', as: :faq
  get '/help' => 'home#help', as: :help

  get '/home' => 'users#home', as: :home
  get '/user' => 'users#show', as: :user
  get '/user/edit' => 'users#edit', as: :edit_user
  put '/user/update' => 'users#update'

  match '/:action' => 'home', via: [:get, :post]
  match '/:controller/:action', via: [:get, :post]

  root to: 'home#index'
end
