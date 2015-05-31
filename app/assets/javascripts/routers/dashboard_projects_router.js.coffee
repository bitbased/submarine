class Submarine.Routers.DashboardProjects extends Backbone.Router
  routes:
    'dashboard/projects': 'index'
    'dashboard/projects/:id': 'show'
    'dashboard/projects/:id/edit': 'edit'

  initialize: ->
    @clients_collection = new Submarine.Collections.Clients()
    @clients_collection.reset(Submarine.Cache["Clients"])

    @collection = new Submarine.Collections.Projects(clients_collection: @clients_collection)
    @collection.reset(Submarine.Cache["Projects"]) #reset($('#projects_container').data('projects'))

  index: ->
    view = new Submarine.Views.DashboardProjectsIndex(collection: @collection)
    $('#projects_container').html(view.render().el)

  edit: (id) ->
    alert "Project #{id}"
    #view = new Submarine.Views.DashboardProjectsIndex(collection: @collection)
    #$('#projects_container').html(view.render().el)

  show: (id) ->
    alert "Project #{id}"
