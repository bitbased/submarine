class Submarine.Models.Project extends Backbone.RelationalModel
  urlRoot: "/projects"

  defaults:
    status: "new"
    active: true
    due_date: null

  relations: [
    type: Backbone.HasMany
    key: 'project_participants'
    relatedModel: 'Submarine.Models.ProjectParticipant'
    collectionType: 'Submarine.Collections.ProjectParticipants'
    #includeInJSON: ['id', 'name']
    #parse: true
    #reverseRelation: 
    #  key: 'project'
  ,
    type: Backbone.HasMany
    key: 'project_task_category_assignments'
    relatedModel: 'Submarine.Models.ProjectTaskCategoryAssignment'
    collectionType: 'Submarine.Collections.ProjectTaskCategoryAssignments'
    includeInJSON: false# ['id', 'name']
    #parse: true
    #reverseRelation: 
    #  key: 'project'
  ,
    type: Backbone.HasMany
    key: 'task_categories'
    relatedModel: 'Submarine.Models.TaskCategory'
    collectionType: 'Submarine.Collections.TaskCategories'
    includeInJSON: false# ['id', 'name']
    #parse: true
    #reverseRelation: 
    #  key: 'project'
  ,
    type: Backbone.HasMany
    key: 'time_entries'
    relatedModel: 'Submarine.Models.TimeEntry'
    collectionType: 'Submarine.Collections.TimeEntries'
    includeInJSON: false# ['id', 'name']
    #parse: true
    #reverseRelation: 
    #  key: 'project'
  ,
    type: Backbone.HasMany
    key: 'expense_entries'
    relatedModel: 'Submarine.Models.ExpenseEntry'
    collectionType: 'Submarine.Collections.ExpenseEntries'
    includeInJSON: false# ['id', 'name']
    #parse: true
    #reverseRelation: 
    #  key: 'project'
  ,
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


  initialize: ->
    @get('time_entries').project_id = @get('id')
    @get('expense_entries').project_id = @get('id')
    @get('project_task_category_assignments').project_id = @get('id')
    @get('task_categories').project_id = @get('id')
    #@client = new Submarine.Models.Client
    #@client.url = "/client/#{@get('client_id')}"
    #@client.fetch
    #alert(@client.id)
    #@

  markActive: ->
    @set status: 'active'
    @set active: true
    @save
  markAttention: ->
    @set status: 'attention'
    @set active: true
    @save
  markComplete: ->
    @set status: 'completed'
    @set active: false
    @save
    @trigger 'fade'
