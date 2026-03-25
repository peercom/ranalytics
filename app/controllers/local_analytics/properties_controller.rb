# frozen_string_literal: true

module LocalAnalytics
  class PropertiesController < ApplicationController
    before_action :set_property, only: [:show, :edit, :update, :destroy]

    def index
      @properties = Property.order(:name)
    end

    def show; end

    def new
      @property = Property.new(timezone: "UTC", currency: "USD", active: true)
    end

    def create
      @property = Property.new(property_params)
      if @property.save
        redirect_to properties_path, notice: "Property created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @property.update(property_params)
        redirect_to properties_path, notice: "Property updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @property.destroy
      redirect_to properties_path, notice: "Property deleted."
    end

    private

    def set_property
      @property = Property.find(params[:id])
    end

    def property_params
      params.require(:property).permit(:name, :timezone, :currency, :active,
                                        :retention_days, allowed_hostnames: [])
    end
  end
end
