class Submarine.Models.Client extends Backbone.RelationalModel
  urlRoot: "/clients"

  relations: [
    type: Backbone.HasMany
    key: 'contacts'
    relatedModel: 'Submarine.Models.Contact'
    collectionType: 'Submarine.Collections.Contacts'
    includeInJSON: false# ['id', 'name']
    #parse: true
    #reverseRelation: 
    #  key: 'project'
  ]
