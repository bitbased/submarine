class Submarine.Models.ProjectTaskCategoryAssignment extends Backbone.RelationalModel
  urlRoot: "/project_task_category_assignments"

  relations: [
    type: Backbone.HasOne
    key: 'task_category'
    keyDestination: 'task_category'
    relatedModel: 'Submarine.Models.TaskCategory'
    collectionType: 'Submarine.Collections.TaskCategories'
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
    #  includeInJSON: 'id'
  ]
