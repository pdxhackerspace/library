Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  get '/login', to: 'sessions#new', as: :login
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy', as: :logout

  get '/auth/:provider/callback', to: 'omniauth#callback'
  get '/auth/failure', to: 'omniauth#failure'

  resources :books do
    collection do
      post :scan_isbn
      post :lookup_metadata
    end
    member do
      post :lookup_metadata
      post :checkout
      post :return
    end
  end

  resources :authors, only: %i[index show]
  resources :locations, only: %i[index show]
  resources :subjects, only: %i[index show]
  get 'search', to: 'search#index', as: :search
  resources :publishers, only: %i[index show], param: :name
  resources :users, only: %i[index show]

  resources :loans, only: [:index, :show]

  resource :settings, only: %i[show update] do
    get :books_csv, on: :member
    resources :locations, only: %i[create update destroy], module: :settings
  end

  root 'home#index'

  get 'home', to: 'home#index', as: :home

  if Rails.env.test?
    post 'test/sign_in', to: 'test_sessions#create', as: :test_sign_in
  end
end
