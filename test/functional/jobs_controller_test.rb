require 'test_helper'

class JobsControllerTest < ActionController::TestCase
  setup do
    @job = jobs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:jobs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create job" do
    assert_difference('Job.count') do
      post :create, job: { active: @job.active, archived: @job.archived, audit_log: @job.audit_log, change_time: @job.change_time, close_date: @job.close_date, code: @job.code, data: @job.data, deleted: @job.deleted, description: @job.description, due_date: @job.due_date, focus: @job.focus, history: @job.history, locked: @job.locked, name: @job.name, notes: @job.notes, open_date: @job.open_date, permalog: @job.permalog, priority: @job.priority, progress: @job.progress, start_date: @job.start_date, state: @job.state, status: @job.status, sync: @job.sync, sync_time: @job.sync_time, tags: @job.tags, visible: @job.visible }
    end

    assert_redirected_to job_path(assigns(:job))
  end

  test "should show job" do
    get :show, id: @job
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @job
    assert_response :success
  end

  test "should update job" do
    put :update, id: @job, job: { active: @job.active, archived: @job.archived, audit_log: @job.audit_log, change_time: @job.change_time, close_date: @job.close_date, code: @job.code, data: @job.data, deleted: @job.deleted, description: @job.description, due_date: @job.due_date, focus: @job.focus, history: @job.history, locked: @job.locked, name: @job.name, notes: @job.notes, open_date: @job.open_date, permalog: @job.permalog, priority: @job.priority, progress: @job.progress, start_date: @job.start_date, state: @job.state, status: @job.status, sync: @job.sync, sync_time: @job.sync_time, tags: @job.tags, visible: @job.visible }
    assert_redirected_to job_path(assigns(:job))
  end

  test "should destroy job" do
    assert_difference('Job.count', -1) do
      delete :destroy, id: @job
    end

    assert_redirected_to jobs_path
  end
end
