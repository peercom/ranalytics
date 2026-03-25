# frozen_string_literal: true

Rails.application.routes.draw do
  mount LocalAnalytics::Engine, at: "/analytics"
end
