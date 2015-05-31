require 'test_helper'

class ContactsControllerTest < ActionController::TestCase
  setup do
    @contact = contacts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:contacts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create contact" do
    assert_difference('Contact.count') do
      post :create, contact: { active: @contact.active, archived: @contact.archived, audit_log: @contact.audit_log, change_time: @contact.change_time, company: @contact.company, data: @contact.data, deleted: @contact.deleted, email: @contact.email, fax_number: @contact.fax_number, first_name: @contact.first_name, history: @contact.history, last_name: @contact.last_name, locked: @contact.locked, mobile_number: @contact.mobile_number, notes: @contact.notes, office_number: @contact.office_number, permalog: @contact.permalog, priority: @contact.priority, shared: @contact.shared, state: @contact.state, sync: @contact.sync, sync_time: @contact.sync_time, tags: @contact.tags, title: @contact.title, visible: @contact.visible }
    end

    assert_redirected_to contact_path(assigns(:contact))
  end

  test "should show contact" do
    get :show, id: @contact
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @contact
    assert_response :success
  end

  test "should update contact" do
    put :update, id: @contact, contact: { active: @contact.active, archived: @contact.archived, audit_log: @contact.audit_log, change_time: @contact.change_time, company: @contact.company, data: @contact.data, deleted: @contact.deleted, email: @contact.email, fax_number: @contact.fax_number, first_name: @contact.first_name, history: @contact.history, last_name: @contact.last_name, locked: @contact.locked, mobile_number: @contact.mobile_number, notes: @contact.notes, office_number: @contact.office_number, permalog: @contact.permalog, priority: @contact.priority, shared: @contact.shared, state: @contact.state, sync: @contact.sync, sync_time: @contact.sync_time, tags: @contact.tags, title: @contact.title, visible: @contact.visible }
    assert_redirected_to contact_path(assigns(:contact))
  end

  test "should destroy contact" do
    assert_difference('Contact.count', -1) do
      delete :destroy, id: @contact
    end

    assert_redirected_to contacts_path
  end
end
