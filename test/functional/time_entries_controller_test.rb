require 'test_helper'

class TimeEntriesControllerTest < ActionController::TestCase
  setup do
    @time_entry = time_entries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:time_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create time_entry" do
    assert_difference('TimeEntry.count') do
      post :create, time_entry: { active: @time_entry.active, active_timer: @time_entry.active_timer, archived: @time_entry.archived, audit_log: @time_entry.audit_log, billable: @time_entry.billable, billed: @time_entry.billed, category: @time_entry.category, change_time: @time_entry.change_time, data: @time_entry.data, date: @time_entry.date, deleted: @time_entry.deleted, end_time: @time_entry.end_time, history: @time_entry.history, hours: @time_entry.hours, idle: @time_entry.idle, locked: @time_entry.locked, notes: @time_entry.notes, permalog: @time_entry.permalog, priority: @time_entry.priority, start_time: @time_entry.start_time, state: @time_entry.state, status: @time_entry.status, sync: @time_entry.sync, sync_time: @time_entry.sync_time, tags: @time_entry.tags, timers: @time_entry.timers, visible: @time_entry.visible }
    end

    assert_redirected_to time_entry_path(assigns(:time_entry))
  end

  test "should show time_entry" do
    get :show, id: @time_entry
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @time_entry
    assert_response :success
  end

  test "should update time_entry" do
    put :update, id: @time_entry, time_entry: { active: @time_entry.active, active_timer: @time_entry.active_timer, archived: @time_entry.archived, audit_log: @time_entry.audit_log, billable: @time_entry.billable, billed: @time_entry.billed, category: @time_entry.category, change_time: @time_entry.change_time, data: @time_entry.data, date: @time_entry.date, deleted: @time_entry.deleted, end_time: @time_entry.end_time, history: @time_entry.history, hours: @time_entry.hours, idle: @time_entry.idle, locked: @time_entry.locked, notes: @time_entry.notes, permalog: @time_entry.permalog, priority: @time_entry.priority, start_time: @time_entry.start_time, state: @time_entry.state, status: @time_entry.status, sync: @time_entry.sync, sync_time: @time_entry.sync_time, tags: @time_entry.tags, timers: @time_entry.timers, visible: @time_entry.visible }
    assert_redirected_to time_entry_path(assigns(:time_entry))
  end

  test "should destroy time_entry" do
    assert_difference('TimeEntry.count', -1) do
      delete :destroy, id: @time_entry
    end

    assert_redirected_to time_entries_path
  end
end
