# frozen_string_literal: true

require "test_helper"

class ApiV1IntegrationTest < ActionDispatch::IntegrationTest
  def login_as(user)
    post "/login", params: { email: user.email, password: "TestPass123!" }
    follow_redirect! if response.redirect?
  end

  def api_headers
    { "Accept" => "application/json", "Content-Type" => "application/json" }
  end

  setup do
    # Create test user with researcher role
    @user = User.create!(
      email: "researcher@test.com",
      password: "TestPass123!",
      password_confirmation: "TestPass123!",
      role: :researcher
    )

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

    # Create test reading stimulus
    @stimulus = ReadingStimulus.create!(
      title: "Test Stimulus",
      body: "This is a test reading passage for testing.",
      reading_level: "Grade 3"
    )

    # Create test item
    @item = Item.create!(
      code: "TEST-ITEM-001",
      item_type: "mcq",
      prompt: "This is a test question for the MCQ type.",
      difficulty: "medium",
      status: "active",
      evaluation_indicator_id: @indicator.id,
      sub_indicator_id: @sub_indicator.id,
      stimulus_id: @stimulus.id
    )
  end

  # Test SubIndicators Index
  test "should list all sub indicators" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }
    get "/api/v1/sub_indicators", headers: { "Accept" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_not_nil json_response["data"]
    assert_not_nil json_response["meta"]
  end

  # Test SubIndicators Show
  test "should show a specific sub indicator" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }
    get "/api/v1/sub_indicators/#{@sub_indicator.id}", headers: { "Accept" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal @sub_indicator.id, json_response["data"]["id"]
    assert_equal @sub_indicator.name, json_response["data"]["name"]
  end

  # Test SubIndicators Create
  test "should create a new sub indicator" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }

    sub_indicator_params = {
      sub_indicator: {
        evaluation_indicator_id: @indicator.id,
        code: "NEW-SUB-001",
        name: "New Sub Indicator",
        description: "This is a new sub indicator for testing."
      }
    }

    post "/api/v1/sub_indicators",
         params: sub_indicator_params,
         headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

    assert_response :created
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "NEW-SUB-001", json_response["data"]["code"]
  end

  # Test SubIndicators Update
  test "should update a sub indicator" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }

    sub_indicator_params = {
      sub_indicator: {
        name: "Updated Sub Indicator Name"
      }
    }

    patch "/api/v1/sub_indicators/#{@sub_indicator.id}",
          params: sub_indicator_params,
          headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "Updated Sub Indicator Name", json_response["data"]["name"]
  end

  # Test SubIndicators Delete
  test "should delete a sub indicator" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }

    # Create a sub indicator to delete
    sub_to_delete = SubIndicator.create!(
      evaluation_indicator_id: @indicator.id,
      code: "DEL-SUB-001",
      name: "Sub to Delete"
    )

    delete "/api/v1/sub_indicators/#{sub_to_delete.id}",
           headers: { "Accept" => "application/json" }

    assert_response :no_content
    assert_nil SubIndicator.find_by(id: sub_to_delete.id)
  end

  # Test Items Index
  test "should list all items" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }
    get "/api/v1/items", headers: { "Accept" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_not_nil json_response["data"]
    assert_not_nil json_response["meta"]
  end

  # Test Items Index with Filter
  test "should list items filtered by evaluation indicator" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }
    get "/api/v1/items?filter[evaluation_indicator_id]=#{@indicator.id}",
        headers: { "Accept" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    # Should include the item we created
    assert json_response["data"].any? { |i| i["id"] == @item.id }
  end

  # Test Items Show
  test "should show a specific item" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }
    get "/api/v1/items/#{@item.id}", headers: { "Accept" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal @item.id, json_response["data"]["id"]
    assert_equal @item.code, json_response["data"]["code"]
    assert_equal "mcq", json_response["data"]["item_type"]
  end

  # Test Items Create
  test "should create a new item" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }

    item_params = {
      item: {
        code: "NEW-ITEM-001",
        item_type: "constructed",
        prompt: "Write a short answer to this constructed response question.",
        explanation: "The expected answer should include...",
        difficulty: "hard",
        status: "active",
        evaluation_indicator_id: @indicator.id,
        sub_indicator_id: @sub_indicator.id
      }
    }

    post "/api/v1/items",
         params: item_params,
         headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

    assert_response :created
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "NEW-ITEM-001", json_response["data"]["code"]
    assert_equal "constructed", json_response["data"]["item_type"]
  end

  # Test Items Update
  test "should update an item" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }

    item_params = {
      item: {
        difficulty: "easy",
        explanation: "Updated explanation text"
      }
    }

    patch "/api/v1/items/#{@item.id}",
          params: item_params,
          headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "easy", json_response["data"]["difficulty"]
    assert_equal "Updated explanation text", json_response["data"]["explanation"]
  end

  # Test Items Delete
  test "should delete an item" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }

    # Create an item to delete
    item_to_delete = Item.create!(
      code: "DEL-ITEM-001",
      item_type: "mcq",
      prompt: "Item to delete",
      status: "draft"
    )

    delete "/api/v1/items/#{item_to_delete.id}",
           headers: { "Accept" => "application/json" }

    assert_response :no_content
    assert_nil Item.find_by(id: item_to_delete.id)
  end

  # Test Nested Sub Indicators Under Evaluation Indicator
  test "should list sub indicators nested under evaluation indicator" do
    post "/login", params: { email: @user.email, password: "TestPass123!" }
    get "/api/v1/evaluation_indicators/#{@indicator.id}/sub_indicators",
        headers: { "Accept" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    # Should include the sub indicator we created
    assert json_response["data"].any? { |s| s["id"] == @sub_indicator.id }
  end

  # Test Authorization - Non-authorized user should not be able to create
  test "should deny creation to non-researcher user" do
    # Create a non-researcher user
    regular_user = User.create!(
      email: "regular@test.com",
      password: "TestPass123!",
      password_confirmation: "TestPass123!"
    )

    post "/login", params: { email: regular_user.email, password: "TestPass123!" }

    sub_indicator_params = {
      sub_indicator: {
        evaluation_indicator_id: @indicator.id,
        code: "UNAUTH-001",
        name: "Should Fail"
      }
    }

    post "/api/v1/sub_indicators",
         params: sub_indicator_params,
         headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

    assert_response :forbidden
  end
end
