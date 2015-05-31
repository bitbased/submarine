require 'test_helper'

class InformationControllerTest < ActionController::TestCase
  setup do
    @information = information(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:information)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create information" do
    assert_difference('Information.count') do
      post :create, information: { active: @information.active, archived: @information.archived, audit_log: @information.audit_log, change_time: @information.change_time, data: @information.data, deleted: @information.deleted, description: @information.description, history: @information.history, items: @information.items, locked: @information.locked, name: @information.name, notes: @information.notes, permalog: @information.permalog, priority: @information.priority, secure_items: @information.secure_items, secure_params: @information.secure_params, state: @information.state, sync: @information.sync, sync_time: @information.sync_time, tags: @information.tags, template: @information.template, visible: @information.visible }
    end

    assert_redirected_to information_path(assigns(:information))
  end

  test "should show information" do
    get :show, id: @information
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @information
    assert_response :success
  end

  test "should update information" do
    put :update, id: @information, information: { active: @information.active, archived: @information.archived, audit_log: @information.audit_log, change_time: @information.change_time, data: @information.data, deleted: @information.deleted, description: @information.description, history: @information.history, items: @information.items, locked: @information.locked, name: @information.name, notes: @information.notes, permalog: @information.permalog, priority: @information.priority, secure_items: @information.secure_items, secure_params: @information.secure_params, state: @information.state, sync: @information.sync, sync_time: @information.sync_time, tags: @information.tags, template: @information.template, visible: @information.visible }
    assert_redirected_to information_path(assigns(:information))
  end

  test "should destroy information" do
    assert_difference('Information.count', -1) do
      delete :destroy, id: @information
    end

    assert_redirected_to information_index_path
  end
end
