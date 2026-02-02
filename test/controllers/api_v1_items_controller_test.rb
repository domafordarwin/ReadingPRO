# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ItemsControllerTest < ActionController::TestCase
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/json'

        # Create test user with researcher role
        @user = User.create!(
          email: 'researcher@test.com',
          password: 'TestPass123!',
          password_confirmation: 'TestPass123!',
          role: :researcher
        )

        # Log in the user
        @request.session[:user_id] = @user.id

        # Create test evaluation indicator
        @indicator = EvaluationIndicator.create!(
          code: 'TEST-IND-001',
          name: 'Test Indicator',
          level: 1
        )

        # Create test sub indicator
        @sub_indicator = SubIndicator.create!(
          evaluation_indicator_id: @indicator.id,
          code: 'TEST-SUB-001',
          name: 'Test Sub Indicator'
        )

        # Create test reading stimulus
        @stimulus = ReadingStimulus.create!(
          title: 'Test Stimulus',
          body: 'This is a test reading passage for testing.',
          reading_level: 'Grade 3'
        )

        # Create test item
        @item = Item.create!(
          code: 'TEST-ITEM-001',
          item_type: 'mcq',
          prompt: 'This is a test question for the MCQ type.',
          difficulty: 'medium',
          status: 'active',
          evaluation_indicator_id: @indicator.id,
          sub_indicator_id: @sub_indicator.id,
          stimulus_id: @stimulus.id
        )
      end

      test 'should get index' do
        get :index
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response['success']
        assert_not_nil json_response['data']
        assert_not_nil json_response['meta']
      end

      test 'should get show' do
        get :show, params: { id: @item.id }
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response['success']
        assert_equal @item.id, json_response['data']['id']
        assert_equal @item.code, json_response['data']['code']
      end

      test 'should create item' do
        item_params = {
          item: {
            code: 'NEW-ITEM-001',
            item_type: 'constructed',
            prompt: 'Write a short answer to this question.',
            difficulty: 'hard',
            status: 'active',
            evaluation_indicator_id: @indicator.id
          }
        }

        post :create, params: item_params
        assert_response :created
        json_response = JSON.parse(@response.body)
        assert json_response['success']
        assert_equal 'NEW-ITEM-001', json_response['data']['code']
        assert_equal 'constructed', json_response['data']['item_type']
      end

      test 'should update item' do
        item_params = {
          item: {
            difficulty: 'easy',
            explanation: 'Updated explanation'
          }
        }

        patch :update, params: item_params.merge(id: @item.id)
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response['success']
        assert_equal 'easy', json_response['data']['difficulty']
      end

      test 'should destroy item' do
        delete :destroy, params: { id: @item.id }
        assert_response :no_content
        assert_nil Item.find_by(id: @item.id)
      end

      test 'should filter by evaluation_indicator' do
        get :index, params: { filter: { evaluation_indicator_id: @indicator.id } }
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response['success']
        assert json_response['data'].any? { |i| i['id'] == @item.id }
      end

      test 'should filter by sub_indicator' do
        get :index, params: { filter: { sub_indicator_id: @sub_indicator.id } }
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response['success']
        assert json_response['data'].any? { |i| i['id'] == @item.id }
      end

      test 'should search by code' do
        get :index, params: { search: 'TEST-ITEM' }
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response['success']
        assert json_response['data'].any? { |i| i['code'].include?('TEST-ITEM') }
      end

      test 'should filter by item_type' do
        get :index, params: { filter: { item_type: 'mcq' } }
        assert_response :success
        json_response = JSON.parse(@response.body)
        assert json_response['success']
        assert json_response['data'].all? { |i| i['item_type'] == 'mcq' }
      end

      test 'should deny creation to non-researcher user' do
        # Create non-researcher user
        regular_user = User.create!(
          email: 'regular@test.com',
          password: 'TestPass123!',
          password_confirmation: 'TestPass123!',
          role: :student
        )

        @request.session[:user_id] = regular_user.id

        item_params = {
          item: {
            code: 'UNAUTH-001',
            item_type: 'mcq',
            prompt: 'Should fail'
          }
        }

        post :create, params: item_params
        assert_response :forbidden
      end
    end
  end
end
