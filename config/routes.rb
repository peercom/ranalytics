# frozen_string_literal: true

LocalAnalytics::Engine.routes.draw do
  # Tracking endpoints (no auth required)
  post "t", to: "tracking#create", as: :tracking_create
  get  "t", to: "tracking#pixel", as: :tracking_pixel

  # Admin UI
  root to: "dashboard#show"

  resource :dashboard, only: [:show], controller: "dashboard" do
    get :export, on: :collection
  end

  resource :real_time, only: [:show], controller: "real_time"

  resources :pages, only: [:index] do
    get :export, on: :collection
  end

  resources :referrers, only: [:index] do
    get :export, on: :collection
  end

  resources :campaigns, only: [:index] do
    get :export, on: :collection
  end

  resources :goals do
    get :export, on: :collection
  end

  resources :events, only: [:index] do
    get :export, on: :collection
  end

  resources :devices, only: [:index] do
    get :export, on: :collection
  end

  resources :locations, only: [:index] do
    get :export, on: :collection
  end

  resources :site_search, only: [:index], controller: "site_search" do
    get :export, on: :collection
  end

  resources :visitor_log, only: [:index], controller: "visitor_log"
  resources :visitor_profiles, only: [:show], path: "visitors"

  resources :report_subscriptions do
    post :send_now, on: :member
  end

  resources :properties
end
