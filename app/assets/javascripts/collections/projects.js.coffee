class Submarine.Collections.Projects extends Backbone.Collection
  url: ->
    if @client_id
      "/clients/#{@client_id}/projects"
    else
      "/projects"

  model: Submarine.Models.Project
  client_id: null

  initialize: (options) ->
    @clients_collection = options.clients_collection

  comparator: (model, dir) ->
    "#{@clients_collection.get(model.get('client_id')).get('name') if model.get('client_id') } - #{ if model.get('code') && model.get('code').indexOf("-") !=-1 then model.get('code') else "" } #{model.get('name')}"

  filterWithText: (rx) ->
    q = rx.toLowerCase().replace(/\./g,"").replace(/'/g,"").replace(/-/g,"").split('')
    _ @models.filter (c) =>
      name = (c.get('code') + " " + (@clients_collection.get(c.get('client_id')).get('name') if c.get('client_id')) + (" " + @clients_collection.get(c.get('secondary_client_id')).get('name') if c.get('secondary_client_id')) + " " + c.get('name') + " " +  c.get('status').replace(/_/g," ")).toLowerCase().replace(/\./g,"").replace(/'/g,"").replace(/-/g,"")
      return name.indexOf(q) != -1

  filterWithFuzzyText: (rx) ->
    q = rx.toLowerCase().split('')
    _ @models.filter (c) =>
      name = (c.get('code') + " " + (@clients_collection.get(c.get('client_id')).get('name') if c.get('client_id')) + (" " + @clients_collection.get(c.get('secondary_client_id')).get('name') if c.get('secondary_client_id')) + " " + c.get('name') + " " +  c.get('status').replace(/_/g," ")).toLowerCase()
      i = 0
      for c in name
        if c == q[i]
          i++
      return if i >= q.length then true else false

  filterWithRegEx: (rx) ->
    _ @models.filter (c) =>
      rx.test(c.get('code') + " " + (@clients_collection.get(c.get('client_id')).get('name') if c.get('client_id')) + (" " + @clients_collection.get(c.get('secondary_client_id')).get('name') if c.get('secondary_client_id')) + " " + c.get('name') + " " + c.get('status').replace(/_/g," "))

  filterWithUser: (user_id) ->
    _ @models.filter (c) ->
      for p in c.get('project_participants').models
        return true if p.get("user_id") == user_id
