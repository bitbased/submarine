window.Submarine =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Cache: {}
  initialize: -> 
    new Submarine.Routers.DashboardProjects()
    Backbone.history.start(pushState: true)

$(document).ready ->
  Submarine.initialize()




#class Submarine.Presenter
#  constructor: (model) ->
#    @model = model
#    (@[key] = value unless @[key]?) for own key, value of @model.attributes
#  get: (name) ->
#    @model.get(name)

