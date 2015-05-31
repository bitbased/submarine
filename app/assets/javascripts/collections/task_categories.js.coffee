class Submarine.Collections.TaskCategories extends Backbone.Collection
  url: ->
    if @project_id
      "/projects/#{@project_id}/task_categories"
    else
      "/task_categories"

  model: Submarine.Models.TaskCategory
  project_id: null