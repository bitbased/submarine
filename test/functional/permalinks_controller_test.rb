require 'test_helper'

class PermalinksControllerTest < ActionController::TestCase
  setup do
    @permalink = permalinks(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:permalinks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create permalink" do
    assert_difference('Permalink.count') do
      post :create, permalink: { active: @permalink.active, archived_on: @permalink.archived_on, audit_log: @permalink.audit_log, change_time: @permalink.change_time, data: @permalink.data, deleted_at: @permalink.deleted_at, description: @permalink.description, destination: @permalink.destination, draft: @permalink.draft, drafting: @permalink.drafting, history: @permalink.history, locked_on: @permalink.locked_on, name: @permalink.name, permalog: @permalink.permalog, priority: @permalink.priority, slug: @permalink.slug, state: @permalink.state, sync: @permalink.sync, sync_time: @permalink.sync_time, visible: @permalink.visible }
    end

    assert_redirected_to permalink_path(assigns(:permalink))
  end

  test "should show permalink" do
    get :show, id: @permalink
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @permalink
    assert_response :success
  end

  test "should update permalink" do
    put :update, id: @permalink, permalink: { active: @permalink.active, archived_on: @permalink.archived_on, audit_log: @permalink.audit_log, change_time: @permalink.change_time, data: @permalink.data, deleted_at: @permalink.deleted_at, description: @permalink.description, destination: @permalink.destination, draft: @permalink.draft, drafting: @permalink.drafting, history: @permalink.history, locked_on: @permalink.locked_on, name: @permalink.name, permalog: @permalink.permalog, priority: @permalink.priority, slug: @permalink.slug, state: @permalink.state, sync: @permalink.sync, sync_time: @permalink.sync_time, visible: @permalink.visible }
    assert_redirected_to permalink_path(assigns(:permalink))
  end

  test "should destroy permalink" do
    assert_difference('Permalink.count', -1) do
      delete :destroy, id: @permalink
    end

    assert_redirected_to permalinks_path
  end
end
