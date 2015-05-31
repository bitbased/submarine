class Submarine.Collections.Contacts extends Backbone.Collection
  url: ->
    if @project_id
      "/projects/#{@project_id}/contacts"
    else if @client_id
      "/clients/#{@client_id}/contacts"
    else
      "/contacts"

  model: Submarine.Models.Contact
  project_id: null
  client_id: null
