class Submarine.Views.DashboardProjectDetailsTimeEntry extends Backbone.View
  template: JST['dashboard_projects/details/time_entry']
  tagName: 'div'
  className: 'time-entry-view'

  initialize: (options) ->
    @model.on('change', @render, @)

    @users_collection = options.users_collection
    @tasks_collection = options.tasks_collection

    @$el.html this.template @

  loadTaskCategories: ->
    if @$(".edit-task-category-id").length > 0
      @$inputTaskCategory.empty()
      cid = @model.get('task_category_id')
      for task in @tasks_collection.models
        @$inputTaskCategory.append("<option value='#{task.get('id')}' #{ "selected" if task.get('id') == cid }>#{task.get('name')}</option>")

  edit: ->
    @$el.addClass('editing')
    @loadTaskCategories()

  render: ->
    if @model.id
      @$el.addClass "model-cid-#{@model.id}"
      @$el.removeClass "new-entry"
    else
      @$el.addClass "new-entry"

    @$inputTaskCategory = @$('.edit-task-category-id')
    @trigger('post-render')
    @