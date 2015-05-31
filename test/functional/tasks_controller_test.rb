require 'test_helper'

class TasksControllerTest < ActionController::TestCase
  setup do
    @task = tasks(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tasks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create task" do
    assert_difference('Task.count') do
      post :create, task: { active: @task.active, archived: @task.archived, audit_log: @task.audit_log, change_time: @task.change_time, close_date: @task.close_date, data: @task.data, deleted: @task.deleted, due_date: @task.due_date, focus: @task.focus, history: @task.history, locked: @task.locked, name: @task.name, notes: @task.notes, open_date: @task.open_date, permalog: @task.permalog, priority: @task.priority, progress: @task.progress, start_date: @task.start_date, state: @task.state, status: @task.status, sync: @task.sync, sync_time: @task.sync_time, tags: @task.tags, visible: @task.visible }
    end

    assert_redirected_to task_path(assigns(:task))
  end

  test "should show task" do
    get :show, id: @task
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @task
    assert_response :success
  end

  test "should update task" do
    put :update, id: @task, task: { active: @task.active, archived: @task.archived, audit_log: @task.audit_log, change_time: @task.change_time, close_date: @task.close_date, data: @task.data, deleted: @task.deleted, due_date: @task.due_date, focus: @task.focus, history: @task.history, locked: @task.locked, name: @task.name, notes: @task.notes, open_date: @task.open_date, permalog: @task.permalog, priority: @task.priority, progress: @task.progress, start_date: @task.start_date, state: @task.state, status: @task.status, sync: @task.sync, sync_time: @task.sync_time, tags: @task.tags, visible: @task.visible }
    assert_redirected_to task_path(assigns(:task))
  end

  test "should destroy task" do
    assert_difference('Task.count', -1) do
      delete :destroy, id: @task
    end

    assert_redirected_to tasks_path
  end
end
