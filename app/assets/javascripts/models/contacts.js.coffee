class Submarine.Models.Contact extends Backbone.RelationalModel
  urlRoot: "/contacts"
  relations: [
    type: Backbone.HasOne
    key: 'client'
    keyDestination: 'client'
    relatedModel: 'Submarine.Models.Client'
    collectionType: 'Submarine.Collections.Clients'
    #includeInJSON: ['id', 'name']
    parse: true
    #reverseRelation: 
    #  key: 'projects'
    #  includeInJSON: 'id'
  ]
