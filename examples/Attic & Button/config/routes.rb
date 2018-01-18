#
#    Copyright 2017, Optimizely and contributors
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

Rails.application.routes.draw do
  resources :demo, only: [:new, :create]
  get 'demo/:user_id/cart', to: 'demo#cart', as: :cart
  get 'demo/:user_id/checkout_cart', to: 'demo#checkout_cart', as: :checkout_cart
  post 'demo/:user_id/buy', to: 'demo#buy', as: :buy
  get 'demo/login', to: 'demo#new'
  post 'demo/config', to: 'demo#create'
  post  'demo/:user_id/checkout_payment', to: 'demo#checkout_payment', as: :checkout_payment
  delete 'demo/:user_id/delete_messages', to: 'demo#delete_messages', as: :delete_messages
  delete 'demo/:user_id/delete_cart', to: 'demo#delete_cart', as: :delete_cart
  delete 'demo/logout', to: 'demo#logout', as: :logout
  get 'demo/:user_id/messages', to: 'demo#log_messages', as: :messages
  get "/demo/shop" => "demo#guest_shop", :as => :guest_shop
  get "/demo/:user_id/shop" => "demo#shop", :as => :shop
  get "/demo/:user_id/payment" => "demo#payment", :as => :payment
  put "/demo/:user_id/update_cart" => "demo#update_cart", :as => :update_cart
  get "/show_receipt/:user_id/show_receipt" => "demo#show_receipt", :as => :show_receipt
  # root path
  root 'demo#guest_shop'
end
