Rails.application.routes.draw do

  resources :demo,only: [:new,:create]
  get 'demo/config', to: 'demo#new'
  post 'demo/config', to: 'demo#create'
  get 'demo/select_visitor', to: "demo#visitors", as: :visitors
  get 'demo/shop', to: "demo#shop", as: :shop
  post 'demo/buy', to: "demo#buy", as: :buy
  #root path
  root "home#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end