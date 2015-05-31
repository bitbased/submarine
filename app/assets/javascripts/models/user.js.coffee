class Submarine.Models.User extends Backbone.RelationalModel
  urlRoot: "/users"


  relations: [
    type: Backbone.HasMany
    key: 'time_entries'
    relatedModel: 'Submarine.Models.TimeEntry'
    collectionType: 'Submarine.Collections.TimeEntries'
    includeInJSON: false# ['id', 'name']
    #parse: true
    #reverseRelation: 
    #  key: 'project'
  ]

  initialize: ->
    @get('time_entries').user_id = @get('id')
