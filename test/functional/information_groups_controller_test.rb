require 'test_helper'

class InformationGroupsControllerTest < ActionController::TestCase
  setup do
    @information_group = information_groups(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:information_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create information_group" do
    assert_difference('InformationGroup.count') do
      post :create, information_group: { active: @information_group.active, archived: @information_group.archived, audit_log: @information_group.audit_log, change_time: @information_group.change_time, data: @information_group.data, deleted: @information_group.deleted, description: @information_group.description, history: @information_group.history, locked: @information_group.locked, name: @information_group.name, notes: @information_group.notes, permalog: @information_group.permalog, primary: @information_group.primary, priority: @information_group.priority, state: @information_group.state, sync: @information_group.sync, sync_time: @information_group.sync_time, template: @information_group.template, visible: @information_group.visible }
    end

    assert_redirected_to information_group_path(assigns(:information_group))
  end

  test "should show information_group" do
    get :show, id: @information_group
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @information_group
    assert_response :success
  end

  test "should update information_group" do
    put :update, id: @information_group, information_group: { active: @information_group.active, archived: @information_group.archived, audit_log: @information_group.audit_log, change_time: @information_group.change_time, data: @information_group.data, deleted: @information_group.deleted, description: @information_group.description, history: @information_group.history, locked: @information_group.locked, name: @information_group.name, notes: @information_group.notes, permalog: @information_group.permalog, primary: @information_group.primary, priority: @information_group.priority, state: @information_group.state, sync: @information_group.sync, sync_time: @information_group.sync_time, template: @information_group.template, visible: @information_group.visible }
    assert_redirected_to information_group_path(assigns(:information_group))
  end

  test "should destroy information_group" do
    assert_difference('InformationGroup.count', -1) do
      delete :destroy, id: @information_group
    end

    assert_redirected_to information_groups_path
  end
end
