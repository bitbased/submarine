class Submarine.Views.DashboardProjectsIndex extends Backbone.View
  template: JST['dashboard_projects/index']

  events: ->
    #'submit #new_project': 'createProject'
    #'click #draw': 'markComplete'
    'click #sort_projects': 'sortProjects'
    'click #sort_projects_by_special': 'sortProjects'
    'click #sort_projects_by_code': 'sortProjectsCode'
    'click #sort_projects_by_status': 'sortProjectsStatus'
    'click #sort_projects_by_due_date': 'sortProjectsDate'
    'click #sort_projects_by_activity': 'sortProjectsActivity'
    'keyup #filter_text' : 'filterProjects'

    'click #filter_current_user': 'filterCurrentUser'
    'click #action-new-project': 'newProject'

  initialize: (options) ->
    @view_cache = {}

    #@collection.on('reset', @renderCollection, @) # old style
    @listenTo @collection, 'reset', @renderCollection # new style
    #@collection.on('add', @appendProject, @) # old style
    @listenTo @collection, 'add', @appendProject # new style

    @clients_collection = @collection.clients_collection

    @users_collection = new Submarine.Collections.Users()
    @users_collection.reset(Submarine.Cache["Users"])

    @sortProjects()

  render: ->
    @$el.html @template
    @sortProjects()
    @

  renderCollection: ->
    #@$('#projects .project-container').not(".new-project").remove()

    @$('#projects .project-container').show()
    @collection.each(@appendProject)
    @

  newProject: (project) =>
    view = new Submarine.Views.DashboardProject(model: new Submarine.Models.Project(), users_collection: @users_collection, clients_collection: @clients_collection)
    view.listenTo @, 'clean_up', view.remove # listen for cleanup 'garbage collection'
    @$('#projects').prepend(view.render().el)
    view.editClient()
    view.generateCode()

  appendProject: (project) =>
    unless @view_cache[project.get('id')]
      view = new Submarine.Views.DashboardProject(model: project, users_collection: @users_collection, clients_collection: @clients_collection)
      view.listenTo @, 'clean_up', view.remove # listen for cleanup 'garbage collection'
      @view_cache[project.get('id')] = view.render().el
    @$('#projects').append(@view_cache[project.get('id')])

  makeProjectVisible: (project) =>
    #view = new Submarine.Views.DashboardProject(model: project)
    @$("#projects div.project-container.model-cid-#{project.id}").show()
    #alert()


  sortProjects: (event) ->
    @collection.comparator = (model) ->
      "#{@clients_collection.get(model.get('client_id')).get('name') if model.get('client_id')} - #{ if model.get('code') && model.get('code').indexOf("-") !=-1 then model.get('code') else "" } #{model.get('name')}"
    @collection.sort()
    @renderCollection()
    @

  filterCurrentUser: ->
    @$('div.project-container').hide()
    @$('div.project-container .editing').closest("div.project-container").show()
    for user in @users_collection.models
      if user.get('is_current')
        res = @collection.filterWithUser user.get('id')
        res.each(@makeProjectVisible)
        return @
    @

  filterProjects: ->
    #res = @collection.filterWithText(new RegExp(".*(" + ($("#filter_text").val().toLowerCase().replace(/([a-z\-\[\]\(\)\"\'\s])/g,'.*$1.*') + ").*"))).each(@appendProject)
    # new RegExp(".*(" + ($("#filter_text").val().replace(/([a-z\-\[\]\(\)\"\'\s])/g,'.*$1.*') + ").*"), 'gi')
    @$('div.project-container').hide()
    @$('div.project-container .editing').closest("div.project-container").show()
    res = @collection.filterWithText $("#filter_text").val()
    #@$('#projects').empty() # MEMORY LEAK HERE?
    if res.size() == 0
      res = @collection.filterWithFuzzyText $("#filter_text").val()
      res.each(@makeProjectVisible)
    else
      res.each(@makeProjectVisible)
    @

  sortProjectsCode: (event) ->
    @collection.comparator = (model) ->
      if model.get('code')
        -"#{ model.get('code').replace(/(-.*)/,"") }"
      else
        -""
    @collection.sort()
    @renderCollection()

  sortProjectsStatus: (event) ->
    @collection.comparator = (model) ->
      "#{model.get('status').replace("attention","1").replace("active","3").replace("time_sheet","2")}"
    @collection.sort()
    @renderCollection()

  sortProjectsDate: (event) ->
    @collection.comparator = (model) ->
      "#{if model.get('due_date') then new Date(model.get('due_date')).getTime() else 'z'}"
    @collection.sort()
    @renderCollection()

  sortProjectsActivity: (event) ->
    # NEEDS TO BE WRITTEN ... activity_date passed from server???
    @collection.comparator = (model) ->
      "#{if model.get('due_date') then new Date(model.get('due_date')).getTime() else 'z'}"
    @collection.sort()
    @renderCollection()


  createProject: (event) ->
    event.preventDefault()
    attributes = name: $('#new_project_name').val()
    @collection.create attributes,
      wait: true
      success: -> $('#new_project')[0].reset()
      error: @handleError

  handleError: (project, response) ->
    if response.status == 422
      errors = $.parseJSON(response.responseText).errors
      for attribute, messages of errors
        alert "#{attribute} #{message}" for message in messages


  removeItemViews: ->
    @trigger 'clean_up' # call cleanup listeners

  remove: ->
    @removeItemViews()
    super()
