class Submarine.Collections.ProjectTaskCategoryAssignments extends Backbone.Collection
  url: ->
    if @project_id
      "/projects/#{@project_id}/project_task_category_assignments"
    else
      "/project_task_category_assignments"

  model: Submarine.Models.ProjectTaskCategoryAssignment
  project_id: null
