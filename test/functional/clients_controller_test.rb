require 'test_helper'

class ClientsControllerTest < ActionController::TestCase
  setup do
    @client = clients(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:clients)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create client" do
    assert_difference('Client.count') do
      post :create, client: { active: @client.active, address: @client.address, archived: @client.archived, audit_log: @client.audit_log, change_time: @client.change_time, data: @client.data, deleted: @client.deleted, history: @client.history, locked: @client.locked, name: @client.name, notes: @client.notes, permalog: @client.permalog, priority: @client.priority, state: @client.state, sync: @client.sync, sync_time: @client.sync_time, tags: @client.tags, visible: @client.visible }
    end

    assert_redirected_to client_path(assigns(:client))
  end

  test "should show client" do
    get :show, id: @client
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @client
    assert_response :success
  end

  test "should update client" do
    put :update, id: @client, client: { active: @client.active, address: @client.address, archived: @client.archived, audit_log: @client.audit_log, change_time: @client.change_time, data: @client.data, deleted: @client.deleted, history: @client.history, locked: @client.locked, name: @client.name, notes: @client.notes, permalog: @client.permalog, priority: @client.priority, state: @client.state, sync: @client.sync, sync_time: @client.sync_time, tags: @client.tags, visible: @client.visible }
    assert_redirected_to client_path(assigns(:client))
  end

  test "should destroy client" do
    assert_difference('Client.count', -1) do
      delete :destroy, id: @client
    end

    assert_redirected_to clients_path
  end
end
