class Submarine.Routers.Clients extends Backbone.Router
  routes:
    'clients': 'index'
    'clients/:id': 'show' 

  initialize: -> 
    @collection = new Submarine.Collections.Clients()
    @collection.reset($('#clients_container').data('clients'))

  index: ->
    view = new Submarine.Views.ClientsIndex(collection: @collection)
    $('#clients_container').html(view.render().el)

  show: (id) ->
    alert "Client #{id}"