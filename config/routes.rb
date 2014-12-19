Rails.application.routes.draw do
  root to: 'home#index'

  match '/:action' => 'home', via: [:get, :post]
  match '/:controller/:action', via: [:get, :post]
end
