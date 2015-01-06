Rails.application.routes.draw do
  
  get '' => 'team#index',   constraints: { subdomain: 'team' }
  get '/:action' => 'team', constraints: { subdomain: 'team' }
  scope module: 'team' do
    match '/auth/:action' => 'auth', via: [:get, :post], constraints: { subdomain: 'team' }
  end

  get   '/properties/:slug' => 'properties#show'
  post  '/properties/:slug' => 'properties#update'
  match '/properties/:slug/:action' => 'properties', via: [:get, :post]

  match '/:action' => 'home', via: [:get, :post]
  match '/:controller/:action', via: [:get, :post]

  root to: 'home#index'
end
