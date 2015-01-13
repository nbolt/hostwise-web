Rails.application.routes.draw do
  get '' => 'team#index',   constraints: { subdomain: 'team' }
  get '/:action' => 'team', constraints: { subdomain: 'team' }
  scope module: 'team' do
    match '/auth/:action' => 'auth', via: [:get, :post], constraints: { subdomain: 'team' }
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

  match '/:action' => 'home', via: [:get, :post]
  match '/:controller/:action', via: [:get, :post]

  root to: 'home#index'
end
