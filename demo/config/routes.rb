Rails.application.routes.draw do

  resources :demo,only: [:new,:create]
  post 'demo/buy', to: "demo#buy", as: :buy
  get 'demo/config', to: 'demo#new'
  post 'demo/config', to: 'demo#create'
  delete 'demo/delete_messages', to: "demo#delete_messages", as: :delete_messages
  get 'demo/messages', to: "demo#log_messages", as: :messages
  get 'demo/shop', to: "demo#shop", as: :shop
  get 'demo/visitors', to: "demo#visitors", as: :visitors
  #root path
  root "home#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
