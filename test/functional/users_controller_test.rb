require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, user: { active: @user.active, archived: @user.archived, audit_log: @user.audit_log, change_time: @user.change_time, data: @user.data, deleted: @user.deleted, email: @user.email, history: @user.history, locked: @user.locked, name: @user.name, notes: @user.notes, password_digest: @user.password_digest, permalog: @user.permalog, priority: @user.priority, state: @user.state, sync: @user.sync, sync_time: @user.sync_time, visible: @user.visible }
    end

    assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    get :show, id: @user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user
    assert_response :success
  end

  test "should update user" do
    put :update, id: @user, user: { active: @user.active, archived: @user.archived, audit_log: @user.audit_log, change_time: @user.change_time, data: @user.data, deleted: @user.deleted, email: @user.email, history: @user.history, locked: @user.locked, name: @user.name, notes: @user.notes, password_digest: @user.password_digest, permalog: @user.permalog, priority: @user.priority, state: @user.state, sync: @user.sync, sync_time: @user.sync_time, visible: @user.visible }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to users_path
  end
end
