Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  root "forum#index"

  # Auth
  get    "register", to: "registrations#new",   as: :register
  post   "register", to: "registrations#create"
  get    "login",    to: "sessions#new",         as: :login
  post   "login",    to: "sessions#create"
  delete "logout",   to: "sessions#destroy",     as: :logout
  get    "email-otp", to: "email_otps#show",      as: :email_otp
  post   "email-otp", to: "email_otps#create"
  post   "email-otp/resend", to: "email_otps#resend", as: :resend_email_otp

  # Forum
  get "downloads", to: "downloads#index", as: :downloads
  resources :categories, only: %i[index show]

  resources :subforums, only: %i[show] do
    resources :forum_threads, path: "threads", only: %i[new create]
  end

  resources :forum_threads, path: "threads", only: %i[show edit update destroy] do
    resources :posts, only: %i[create edit update destroy]
    member do
      patch :lock
      patch :unlock
      patch :pin
      patch :unpin
      patch :move
    end
  end

  resources :attachments, only: %i[show destroy] do
    member do
      get :download
      patch :approve
      patch :unapprove
    end
  end

  resources :reputations, only: %i[create destroy]
  resources :reports, only: %i[new create]

  resources :private_messages, path: "messages" do
    collection do
      get :sent
    end
  end

  resources :users, only: %i[show edit update] do
    member do
      patch :ban
      patch :unban
    end
  end

  namespace :admin do
    root "dashboard#index"
    resources :categories, except: :show
    resources :subforums, except: :show
    resources :users, only: %i[index show edit update] do
      member do
        patch :ban
        patch :unban
        patch :flag
        patch :unflag
      end
      resources :user_warnings, only: %i[create destroy], shallow: true
      resources :staff_notes,   only: %i[create destroy], shallow: true
    end
    resources :reports,       only: %i[index show update]
    resources :site_pages,    only: %i[index edit update]
    resources :attack_events, only: %i[index]
    patch "bulk_threads", to: "bulk_threads#update", as: :bulk_threads
    get "forums", to: "forums#index", as: :forums
    get "file_leaderboard", to: "file_leaderboard#index", as: :file_leaderboard
  end

  get "terms",   to: "pages#terms",   as: :terms
  get "privacy", to: "pages#privacy", as: :privacy
  get "rules",   to: "pages#rules",  as: :rules

  get "sitemap.xml", to: "sitemaps#show", as: :sitemap, defaults: { format: :xml }
  get "up", to: "rails/health#show", as: :rails_health_check
end
