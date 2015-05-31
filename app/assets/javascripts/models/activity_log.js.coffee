class Submarine.Models.ActivityLog extends Backbone.Model

  relations: [
    type: Backbone.HasOne
    key: 'project'
    keyDestination: 'project'
    relatedModel: 'Submarine.Models.Project'
    collectionType: 'Submarine.Collections.Projects'
    parse: true
  ]
