Rails.application.routes.draw do
  
  get '' => 'team#index',   constraints: { subdomain: 'team' }
  get '/:action' => 'team', constraints: { subdomain: 'team' }
  scope module: 'team' do
    match '/auth/:action' => 'auth', via: [:get, :post], constraints: { subdomain: 'team' }
  end

  match '/:action' => 'home', via: [:get, :post]
  match '/:controller/:action', via: [:get, :post]

  root to: 'home#index'
end
