# frozen_string_literal: true

#
#    Copyright 2018, Optimizely and contributors
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
  resources :demo, only: %i[new create]

  # Sets default request as root path;
  root 'demo#guest_shop'

  ################ Requests for anonymous user ########################
  # Default request e.g localhost:3000 OR '/'
  get '/demo/shop' => 'demo#guest_shop', as: :guest_shop
  # Renders login form modal
  get 'demo/login', to: 'demo#new'
  # Request on login form sumbit
  post 'demo/config', to: 'demo#create'
  # Deletes logged in user session
  delete 'demo/logout', to: 'demo#logout', as: :logout
  
  ################ Shop page requests ########################
  # Gets shop/Home page
  get '/demo/:user_id/shop' => 'demo#shop', constraints: { user_id:  /.*/ }, as: :shop
  # Buy now button event to add products in cart
  post 'demo/:user_id/buy', to: 'demo#buy', constraints: { user_id:  /.*/ }, as: :buy
  
  ################ Cart page requests ########################
  # Renders cart page
  get 'demo/:user_id/cart', to: 'demo#cart', constraints: { user_id:  /.*/ }, as: :cart
  # Updates cart products
  put '/demo/:user_id/update_cart' => 'demo#update_cart', constraints: { user_id:  /.*/ }, as: :update_cart
  # Sets associative user's cart empty
  delete 'demo/:user_id/delete_cart', to: 'demo#delete_cart', constraints: { user_id:  /.*/ }, as: :delete_cart
  # Renders receipt in modal
  get '/show_receipt/:user_id/show_receipt' => 'demo#show_receipt', constraints: { user_id:  /.*/ }, as: :show_receipt
  # Sets cart empty on successful purchase. Redirects to shop page
  get 'demo/:user_id/checkout_cart', to: 'demo#checkout_cart', constraints: { user_id:  /.*/ }, as: :checkout_cart
  
  ################ Payment page requests ########################
  # Renders payment page when feature is not enabled or in Guest user case.
  get '/demo/:user_id/payment' => 'demo#payment', constraints: { user_id:  /.*/ }, as: :payment
  # Places order for event 'checkout_complete'
  post 'demo/:user_id/checkout_payment', to: 'demo#checkout_payment', constraints: { user_id:  /.*/ }, as: :checkout_payment
  
  ################ Messages page requests ########################
  # Renders messages page
  get 'demo/:user_id/messages', to: 'demo#log_messages', constraints: { user_id:  /.*/ }, as: :messages
  # Deletes log messages of associative user
  delete 'demo/:user_id/delete_messages', to: 'demo#delete_messages', constraints: { user_id:  /.*/ }, as: :delete_messages

  
end
