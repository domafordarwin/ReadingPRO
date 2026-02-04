# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class SubIndicatorsControllerTest < ActionController::TestCase
      setup do
        @request.env["HTTP_ACCEPT"] = "application/json"

        # Create test user with researcher role
        @user = User.create!(
          email: "researcher@test.com",
          password: "TestPass123!",
          password_confirmation: "TestPass123!",
          role: :researcher
        )

        # Log in the user
        @request.session[:user_id] = @user.id

        # Create test evaluation indicator
        @indicator = EvaluationIndicator.create!(
          code: "TEST-IND-001",
          name: "Test Indicator",
          level: 1
        )

        # Create test sub indicator
        @sub_indicator = SubIndicator.create!(
          evaluation_indicator_id: @indicator.id,
          code: "TEST-SUB-001",
          name: "Test Sub Indicator"
        )
      end

      test "should get index" do
        get :index
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response["success"]
        assert_not_nil json_response["data"]
        assert_not_nil json_response["meta"]
      end

      test "should get show" do
        get :show, params: { id: @sub_indicator.id }
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response["success"]
        assert_equal @sub_indicator.id, json_response["data"]["id"]
        assert_equal @sub_indicator.name, json_response["data"]["name"]
      end

      test "should create sub_indicator" do
        sub_indicator_params = {
          sub_indicator: {
            evaluation_indicator_id: @indicator.id,
            code: "NEW-SUB-001",
            name: "New Sub Indicator",
            description: "This is a new sub indicator."
          }
        }

        post :create, params: sub_indicator_params
        assert_response :created
        json_response = JSON.parse(@response.body)
        assert json_response["success"]
        assert_equal "NEW-SUB-001", json_response["data"]["code"]
      end

      test "should update sub_indicator" do
        sub_indicator_params = {
          sub_indicator: {
            name: "Updated Name"
          }
        }

        patch :update, params: sub_indicator_params.merge(id: @sub_indicator.id)
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response["success"]
        assert_equal "Updated Name", json_response["data"]["name"]
      end

      test "should destroy sub_indicator" do
        delete :destroy, params: { id: @sub_indicator.id }
        assert_response :no_content
        assert_nil SubIndicator.find_by(id: @sub_indicator.id)
      end

      test "should filter by indicator" do
        get :index, params: { filter: { evaluation_indicator_id: @indicator.id } }
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response["success"]
        assert json_response["data"].any? { |s| s["id"] == @sub_indicator.id }
      end

      test "should search by name" do
        get :index, params: { search: "Test Sub" }
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response["success"]
        assert json_response["data"].any? { |s| s["name"].include?("Test Sub") }
      end
    end
  end
end
