# frozen_string_literal: true

module LocalAnalytics
  class GoalsController < ApplicationController
    before_action :require_property!
    before_action :set_goal, only: [:show, :edit, :update, :destroy]

    def index
      @goals = current_property.goals.order(:name)
      @report = Reports::GoalsReport.new(
        property: current_property,
        date_range: date_range
      )
    end

    def show
      @report = Reports::GoalDetailReport.new(
        property: current_property,
        goal: @goal,
        date_range: date_range
      )
    end

    def new
      @goal = current_property.goals.build
    end

    def create
      @goal = current_property.goals.build(goal_params)
      if @goal.save
        redirect_to goals_path(property_id: current_property.id), notice: "Goal created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @goal.update(goal_params)
        redirect_to goals_path(property_id: current_property.id), notice: "Goal updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @goal.destroy
      redirect_to goals_path(property_id: current_property.id), notice: "Goal deleted."
    end

    def export
      @report = Reports::GoalsReport.new(
        property: current_property,
        date_range: date_range
      )

      respond_to do |format|
        format.csv do
          send_data @report.to_csv,
                    filename: "goals_#{date_range.first}_#{date_range.last}.csv",
                    type: "text/csv"
        end
      end
    end

    private

    def set_goal
      @goal = current_property.goals.find(params[:id])
    end

    def goal_params
      params.require(:goal).permit(:name, :key, :goal_type, :active, :revenue_default,
                                   match_config: {})
    end
  end
end
