require 'test_helper'

class RolesControllerTest < ActionController::TestCase
  setup do
    @role = roles(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create role" do
    assert_difference('Role.count') do
      post :create, role: { active: @role.active, archived: @role.archived, audit_log: @role.audit_log, change_time: @role.change_time, data: @role.data, deleted: @role.deleted, history: @role.history, locked: @role.locked, name: @role.name, notes: @role.notes, permalog: @role.permalog, priority: @role.priority, state: @role.state, sync: @role.sync, sync_time: @role.sync_time, type: @role.type, visible: @role.visible }
    end

    assert_redirected_to role_path(assigns(:role))
  end

  test "should show role" do
    get :show, id: @role
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @role
    assert_response :success
  end

  test "should update role" do
    put :update, id: @role, role: { active: @role.active, archived: @role.archived, audit_log: @role.audit_log, change_time: @role.change_time, data: @role.data, deleted: @role.deleted, history: @role.history, locked: @role.locked, name: @role.name, notes: @role.notes, permalog: @role.permalog, priority: @role.priority, state: @role.state, sync: @role.sync, sync_time: @role.sync_time, type: @role.type, visible: @role.visible }
    assert_redirected_to role_path(assigns(:role))
  end

  test "should destroy role" do
    assert_difference('Role.count', -1) do
      delete :destroy, id: @role
    end

    assert_redirected_to roles_path
  end
end
