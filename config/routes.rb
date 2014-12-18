Rails.application.routes.draw do
  root to: 'home#index'

  match '/:controller/:action', via: [:get, :post]
end
