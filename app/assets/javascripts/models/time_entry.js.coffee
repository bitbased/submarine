class Submarine.Models.TimeEntry extends Backbone.RelationalModel
  urlRoot: "/time_entries"

  relations: [
    type: Backbone.HasOne
    key: 'user'
    keyDestination: 'user'
    relatedModel: 'Submarine.Models.User'
    collectionType: 'Submarine.Collections.Users'
    #includeInJSON: ['id', 'name']
    parse: true
    #reverseRelation:
    #  key: 'project'
    #  includeInJSON: 'id'
  ,
    type: Backbone.HasOne
    key: 'project'
    keyDestination: 'project'
    relatedModel: 'Submarine.Models.Project'
    collectionType: 'Submarine.Collections.Projects'
    #includeInJSON: ['id', 'name']
    parse: true
    reverseRelation:
      key: 'project'
    #  includeInJSON: 'id'
  ]
