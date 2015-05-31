class Submarine.Views.DashboardProject extends Backbone.View
  template: JST['dashboard_projects/project_container']
  templateProject: JST['dashboard_projects/project_row']
  templateStatus: JST['dashboard_projects/project_status']
  templateModal: JST['dashboard_projects/project_modal']
  tagName: 'div'
  className: 'project-container'

  events: 
    #'click': 'showProject'
    'click .toggle':  'toggleStatus'

    'click .action-archive': 'archiveProject'
    'click .action-restore': 'restoreProject'
    'click .action-show': 'showProject'

    'click .dropdown-toggle': 'dropdownToggle'

    'dblclick .project-notes': 'edit'
    'dblclick .project-date': 'edit'
    'dblclick .project-name': 'edit'
    'dblclick .project-client-name': 'editClient'
    'dblclick .project-secondary-client-name': 'editClient'
    'click .action-edit': 'edit'
    'click .project-icon-column': 'toggleEntries'

    'keypress .edit-date': 'updateOnEnter'
    'keypress .edit-name': 'updateOnEnter'
    'keypress .edit-status': 'updateOnEnter'
    #'keypress .edit-notes': 'updateOnEnter'

    'keydown .edit-date': 'cancelOnEscape'
    'keydown .edit-name': 'cancelOnEscape'
    'keydown .edit-notes': 'cancelOnEscape'
    'keydown .edit-status': 'cancelOnEscape'

    'mousedown .status-select': 'selectStatus'
    'mousedown .user-select': 'selectUser'

    'mousedown .user-action': 'userAction'

    'click .action-save': 'save'
    'click .action-undo': 'undo'

    #'blur .edit-date': 'close'
    #'blur .edit-name': 'close'
    #'blur .edit-notes': 'close'
    #'blur .edit-status': 'close'
    'blur .dropdown-toggle': 'dropdownClose'

    'change .edit-client-id': 'selectClient'
    'change .edit-secondary-client-id': 'selectSecondaryClient'

  initialize: (options) ->
    @model.on('change', @render, @)
    @model.on('fade', @fadeArchived, @)
    @on('post-render', @onPostRender, @)
    @users_collection = options.users_collection
    @clients_collection = options.clients_collection

    @current_user = null
    @users_collection.each (user) =>
      @current_user = user if user.get('is_current')

    @$el.html this.template @

  toggleEntries: ->
    @$el.toggleClass('expanded')
    if @$el.hasClass('expanded')

      unless @time_sheet_view
        @time_sheet_view = new Submarine.Views.DashboardProjectDetailsIndex(model: @current_user.get('time_entries'), user: @current_user, project: @model, users_collection: @users_collection, clients_collection: @clients_collection)
        @$('.details-row').html("")
        @$('.details-row').append(@time_sheet_view.render().el)
      else
        @time_sheet_view.showProjectTime()
      @$(".details-row").slideDown()
    else
      @$(".details-row").slideUp()

  loadClients: ->
    if @$(".edit-client-id").length > 0
      @$inputClient.empty()
      cid = @model.get('client_id')
      for client in @clients_collection.models
        @$inputClient.append("<option value='#{client.get('id')}' #{ "selected" if client.get('id') == cid }>#{client.get('name')}</option>")

    if @$(".edit-secondary-client-id").length > 0
      @$inputSecondaryClient.empty()
      @$inputSecondaryClient.append("<option value=''></option>")
      cid = @model.get('secondary_client_id')
      for client in @clients_collection.models
        @$inputSecondaryClient.append("<option value='#{client.get('id')}' #{ "selected" if client.get('id') == cid }>#{client.get('name')}</option>")


  selectClient: ->
    #@model.set 'client_id', @$(".edit-client-id").val()
  selectSecondaryClient: ->
    #@model.set 'client_id', @$(".edit-client-id").val()

  generateCode: ->
    $.post "/projects/reserve.json?rnd=#{Math.floor((Math.random()*1000)+1)}", {}, (data) =>
      @$(".project-code").html data.code
      @$inputCode.val data.code
    , 'json'

  dropdownToggle: (e) ->
    $(".dropdown-toggle").not($(e.currentTarget)).removeClass("dropdown-active")
    $(e.currentTarget).toggleClass("dropdown-active")

  dropdownClose: (e) ->
    setTimeout =>
      $(e.currentTarget).removeClass("dropdown-active")
    , 50

  showProject: ->
    #Backbone.history.navigate("dashboard/projects/#{@model.get('id')}", true)
    #$("#project_model").html this.templateModal @

    #$("#new-project-overlay").click ->
    #  $("#new-project-overlay").remove()
    #el = document.getElementById("overlay");
    #el.style.visibility = (el.style.visibility == "visible") ? "hidden" : "visible";

  editName: ->
    edit()
    @$inputName.focus().val(@$inputName.val())

  edit: ->
    @$('.project-row').addClass 'editing'
    @loadClients()
  editClient: ->
    @$('.project-row').addClass 'editing'
    @$('.project-row').addClass 'editing-client'
    @loadClients()

  undo: ->
    unless @model.get('id')
      $.post "/projects/release/#{@$inputCode.val()}.json", (data) =>
      @remove()
    else
      @$('.editing, .editing-client').removeClass('editing').removeClass('editing-client')
      @render()

  save: ->
    updates = {}
    value = @$inputDate.val().trim()
    if value == ""
      updates['due_date'] = null if @model.get('due_date') != null
    else
      if new Date(@model.get('due_date')).format("m/dd/yy") != new Date(Date.parse(value)).format('m/dd/yy')
        updates['due_date'] = new Date(Date.parse(value))

    updates['code'] = @$inputCode.val().trim() if @model.get('code') != @$inputCode.val().trim()
    
    if @model.get('client_id') != @$inputClient.val()
      updates['client_id'] = (if @$inputClient.val() then @$inputClient.val() else null)
    if @model.get('secondary_client_id') != @$inputSecondaryClient.val()
      updates['secondary_client_id'] = (if @$inputSecondaryClient.val() then @$inputSecondaryClient.val() else null)

    updates['notes'] = @$inputNotes.val().trim() if @model.get('notes') != @$inputNotes.val().trim()
    updates['name'] = @$inputName.val().trim() if @model.get('name') != @$inputName.val().trim()
    updates['status'] = @$inputStatus.val().trim() if @model.get('status') != @$inputStatus.val().trim()

    @model.save updates, patch: true
    @$('.editing, .editing-client').removeClass('editing').removeClass('editing-client')
    @render()


  fadeArchived: ->
    $('.inactive').removeClass('fade')
    @$('.inactive').addClass('fade')


  render: ->
    @$(".project-row").html this.templateProject @
    $('.loading-spinner').hide()
    if @model.id
      @$el.addClass "model-cid-#{@model.id}"
      @$el.removeClass "new-project"
    else
      @$el.addClass "new-project"
    @$inputDate = @$('.edit-date')
    @$inputName = @$('.edit-name')
    @$inputNotes = @$('.edit-notes')
    @$inputStatus = @$('.edit-status')
    @$inputCode = @$('.edit-code')
    @$inputClient = @$('.edit-client-id')
    @$inputSecondaryClient = @$('.edit-secondary-client-id')
    @trigger('post-render')
    @


  onPostRender: ->
    #@loadClients()


  userAction: (e) ->
    if $(e.currentTarget).data("action") == "remove"
      for participant in @model.get('project_participants').models
        if participant.get('id') == $(e.currentTarget).data("id")
          participant.destroy()
          break
    if $(e.currentTarget).data("action") == "manager"
      for participant in @model.get('project_participants').models
        if participant.get('id') == $(e.currentTarget).data("id")
          participant.save {is_manager: !participant.get('is_manager')}, {patch: true}
          break
    @render()

  selectStatus: (e) ->
    @$inputStatus.val($(e.currentTarget).data("status"))
    @$(".status-dropdown-area").html this.templateStatus { model: @model, status: @$inputStatus.val() }
    @edit()
    
  selectUser: (e) ->
    participant = new Submarine.Models.ProjectParticipant({ project_id: @model.get('id'), user_id: $(e.currentTarget).data("user_id") })
    #participant = @model.get('project_participants').create(participant)
    participant = @model.get('project_participants').create(participant,
      wait: true
      success: =>
        @render()
    )

  archiveProject: ->
    @model.save {active: false}, {patch: true}
    @render()
  restoreProject: ->
    @model.save {active: true}, {patch: true}
    @render()



  cancelOnEscape: (e) ->
    ENTER_KEY = 13
    ESCAPE_KEY = 27
    if e.keyCode == ESCAPE_KEY
      @undo()

  # If you hit `enter`, we're through editing the item.
  updateOnEnter: (e) ->
    ENTER_KEY = 13
    ESCAPE_KEY = 27
    if e.which == ENTER_KEY
      @save()
