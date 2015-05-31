require 'test_helper'

class ActivityLogsControllerTest < ActionController::TestCase
  setup do
    @activity_log = activity_logs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:activity_logs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create activity_log" do
    assert_difference('ActivityLog.count') do
      post :create, activity_log: { activity: @activity_log.activity, activity_time: @activity_log.activity_time, cleared_by: @activity_log.cleared_by, data: @activity_log.data, deleted_at: @activity_log.deleted_at, description: @activity_log.description, history: @activity_log.history, message: @activity_log.message, notes: @activity_log.notes, resource_data: @activity_log.resource_data, resource_id: @activity_log.resource_id, resource_name: @activity_log.resource_name, resource_state: @activity_log.resource_state, resource_type: @activity_log.resource_type, show_to: @activity_log.show_to, starred_by: @activity_log.starred_by, viewed_by: @activity_log.viewed_by, visible: @activity_log.visible }
    end

    assert_redirected_to activity_log_path(assigns(:activity_log))
  end

  test "should show activity_log" do
    get :show, id: @activity_log
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @activity_log
    assert_response :success
  end

  test "should update activity_log" do
    put :update, id: @activity_log, activity_log: { activity: @activity_log.activity, activity_time: @activity_log.activity_time, cleared_by: @activity_log.cleared_by, data: @activity_log.data, deleted_at: @activity_log.deleted_at, description: @activity_log.description, history: @activity_log.history, message: @activity_log.message, notes: @activity_log.notes, resource_data: @activity_log.resource_data, resource_id: @activity_log.resource_id, resource_name: @activity_log.resource_name, resource_state: @activity_log.resource_state, resource_type: @activity_log.resource_type, show_to: @activity_log.show_to, starred_by: @activity_log.starred_by, viewed_by: @activity_log.viewed_by, visible: @activity_log.visible }
    assert_redirected_to activity_log_path(assigns(:activity_log))
  end

  test "should destroy activity_log" do
    assert_difference('ActivityLog.count', -1) do
      delete :destroy, id: @activity_log
    end

    assert_redirected_to activity_logs_path
  end
end
