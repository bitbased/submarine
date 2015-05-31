class Submarine.Views.DashboardProjectDetailsIndex extends Backbone.View
  template: JST['dashboard_projects/details/index']
  tagName: 'div'
  className: 'project-details-view'

  events: ->
    #'submit #new_project': 'createProject'
    #'click #filter_current_user': 'filterCurrentUser'
    'click .day-heading': 'showDay'
    'click .all-time': 'showProjectTime'
    'click .all-expenses': 'showAllExpenses'
    'click .day-heading.selected .new-time-entry': 'newTimeEntry'

  initialize: (options) ->
    @view_cache = {}
    @expense_view_cache = {}

    @users_collection = options.users_collection
    @clients_collection = options.clients_collection
    @user = options.user
    @project = options.project

    @user_time_collection = @user.get("time_entries")
    @project_time_collection = @project.get("time_entries")
    @project_expense_collection = @project.get("expense_entries")

    @user_time_collection.on('reset', @renderTimeCollection, @) # old style
    @user_time_collection.on('add', @appendTimeEntry, @) # old style
    @user_time_collection.on('remove', @removeTimeEntry, @) # old style

    @project_tasks_collection = @project.get("task_categories")
    @project_tasks_collection.on('reset', @renderTaskCollection, @) # old style
    @project_tasks_collection.on('add', @appendTaskEntry, @) # old style

    @project_time_collection.on('reset', @renderTimeCollection, @) # old style
    @project_time_collection.on('add', @appendTimeEntry, @) # old style
    @project_time_collection.on('remove', @removeTimeEntry, @) # old style

    @project_expense_collection.on('reset', @renderExpenseCollection, @) # old style
    @project_expense_collection.on('add', @appendExoenseEntry, @) # old style
    @project_expense_collection.on('remove', @removeExpenseEntry, @) # old style


    @$el.html @template @

    @project_tasks_collection.fetch
      success: =>

    @project_expense_collection.fetch
      success: =>

    if @user_time_collection.models.length == 0
      @user_time_collection.fetch
        success: =>
          @project_time_collection.fetch
            success: =>
              @showTime()
    else
      @project_time_collection.fetch
        success: =>
          @showTime()

  showTime: =>
    beforeOneWeek = new Date()
    day = beforeOneWeek.getDay()
    diffToMonday = beforeOneWeek.getDate() - day + (if day == 0 then -6 else 1)
    lastMonday = new Date(beforeOneWeek.setDate(diffToMonday))

    weekdays = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday']
    weekdates = {}
    hours = {}

    @$(".all-time").attr('data-date', new Date().format("m/dd/yy"))
    @$(".all-expenses").attr('data-date', new Date().format("m/dd/yy"))

    for day_name, i in weekdays
      lastMonday = new Date(new Date(beforeOneWeek).setDate(diffToMonday - 1 + (if i == 0 then 7 else i) ))
      @$(".day-#{day_name}").attr('data-date', lastMonday.format("m/dd/yy"))
      weekdates[lastMonday.format("m/dd/yy")] = day_name
      hours[day_name] = 0
    @user_time_collection.each (entry) =>
      date = new Date(entry.get('date')).format("m/dd/yy")
      if weekdates[date]
        day_name = weekdates[date]
        hours[day_name] += entry.get('hours')
    for day_name in weekdays
      @$(".day-#{day_name} .total-time").html(humanHours(hours[day_name]))

    @showProjectTime



  showDay: (e) ->
    unless $(e.currentTarget).hasClass('selected')
      @$(".header>div").removeClass('selected')
      $(e.currentTarget).addClass('selected')
      date = $(e.currentTarget).attr('data-date')
    @user_time_collection.each (time_entry) =>
      if date == new Date(time_entry.get('date')).format("m/dd/yy") && @user.get('id') == time_entry.get('user_id')
        @appendTimeEntry(time_entry)
      else
        @removeTimeEntry(time_entry)

    @project_time_collection.each (time_entry) =>
      unless date == new Date(time_entry.get('date')).format("m/dd/yy") && @user.get('id') == time_entry.get('user_id')
        @removeTimeEntry(time_entry)

    @project_expense_collection.each (expense_entry) =>
      @removeExpenseEntry(expense_entry)

  showProjectTime: (e) ->
    if e
      unless $(e.currentTarget).hasClass('selected')
        @$(".header>div").removeClass('selected')
        $(e.currentTarget).addClass('selected')
    else
      unless @$(".all-time").hasClass('selected')
        @$(".header>div").removeClass('selected')
        @$(".all-time").addClass('selected')

    @user_time_collection.each (time_entry) =>
      if time_entry.get('project_id') == @project.get('id')
        @appendTimeEntry(time_entry)
      else
        @removeTimeEntry(time_entry)

    @project_time_collection.each (time_entry) =>
      if time_entry.get('project_id') == @project.get('id')
        @appendTimeEntry(time_entry)
      else
        @removeTimeEntry(time_entry)

    @project_expense_collection.each (expense_entry) =>
      @removeExpenseEntry(expense_entry)

  showAllExpenses: (e) ->
    unless $(e.currentTarget).hasClass('selected')
      @$(".header>div").removeClass('selected')
      $(e.currentTarget).addClass('selected')

    @project_expense_collection.each (expense_entry) =>
      if expense_entry.get('project_id') == @project.get('id')
        @appendExpenseEntry(expense_entry)
      else
        @removeExpenseEntry(expense_entry)

    @user_time_collection.each (time_entry) =>
      @removeTimeEntry(time_entry)

    @project_time_collection.each (time_entry) =>
      @removeTimeEntry(time_entry)

  newTimeEntry: ->

    date = new Date(@$(".header>div.selected").attr("data-date"))

    task_category_id = null
    task_category_name = null

    @user_time_collection.each (time) =>
      if time.get('project_id') == @project.get('id') && task_category_id == null
        task_category_id = time.get('task_category_id')
        task_category_name = time.get('task_category_name')

    @project_tasks_collection.each (task) =>
      if task_category_id == null
        task_category_id = task.get('task_category_id')
        task_category_name = task.get('name')

    time_entry = new Submarine.Models.TimeEntry
      'date': date
      'user_id': @user.get('id')
      'project_id': @project.get('id')
      'project_id': @project.get('id')
      'project_code': @project.get('code')
      'project_name': @project.get('name')
      'client_name': @clients_collection.get(@project.get('client_id')).get('name')
      'task_category_id': task_category_id
      'task_category_name': task_category_name
      'hours': 0.0
      'notes': ""

    @new_time_entry_view = new Submarine.Views.DashboardProjectDetailsTimeEntry(model: time_entry, user: @user, users_collection: @users_collection, tasks_collection: @project_tasks_collection)
    @new_time_entry_view.listenTo @, 'clean_up', @new_time_entry_view.remove # listen for cleanup 'garbage collection'
    @$(".time-entries").prepend(@new_time_entry_view.render().el)
    @new_time_entry_view.edit()

  render: ->
    @taskList = @$(".task-assignment-list")
    @trigger('post-render')
    @

  renderTimeCollection: ->
    @user_time_collection.each(@appendTimeEntry)
    @project_time_collection.each(@appendTimeEntry)
    @

  renderTimeCollection: ->
    @project_expense_collection.each(@appendExpenseEntry)
    @

  renderTasksCollection: ->
    @$(".task-assignment-list").empty()
    @project_tasks_collection.each(@appendTaskEntry)
    @

  appendTaskEntry: (task_category) =>
    @$(".task-assignment-list").append("<option value='#{task_category.get('id')}'>#{task_category.get('name')}</option>")


  removeTimeEntry: (time_entry) =>
    if @view_cache[time_entry.get("id")]
      @view_cache[time_entry.get("id")].remove()


  appendTimeEntry: (time_entry) =>
    #alert("stuff")
    unless @view_cache[time_entry.get("id")]
      @view_cache[time_entry.get("id")] = new Submarine.Views.DashboardProjectDetailsTimeEntry(model: time_entry, user: @user, users_collection: @users_collection, tasks_collection: @project_tasks_collection)
      @view_cache[time_entry.get("id")].listenTo @, 'clean_up', @view_cache[time_entry.get("id")].remove # listen for cleanup 'garbage collection'
    
    filter = false
    if @$(".day-heading.selected").length > 0
      date = @$(".day-heading.selected").attr('data-date')
      filter = filter || (date == new Date(time_entry.get('date')).format("m/dd/yy") && @user.get('id') == time_entry.get('user_id'))
    if @$(".all-time.selected").length > 0
      filter = filter || (time_entry.get('project_id') == @project.get('id'))

    @$(".time-entries").append(@view_cache[time_entry.get("id")].render().el) if filter



  removeExpenseEntry: (expense_entry) =>
    if @expense_view_cache[expense_entry.get("id")]
      @expense_view_cache[expense_entry.get("id")].remove()

  appendExpenseEntry: (expense_entry) =>
    #alert("stuff")
    unless @expense_view_cache[expense_entry.get("id")]
      @expense_view_cache[expense_entry.get("id")] = new Submarine.Views.DashboardProjectDetailsExpenseEntry(model: expense_entry, user: @user, users_collection: @users_collection)
      @expense_view_cache[expense_entry.get("id")].listenTo @, 'clean_up', @expense_view_cache[expense_entry.get("id")].remove # listen for cleanup 'garbage collection'
    
    filter = false
    if @$(".all-expenses.selected").length > 0
      filter = filter || (expense_entry.get('project_id') == @project.get('id'))

    @$(".expense-entries").append(@expense_view_cache[expense_entry.get("id")].render().el) if filter




  removeItemViews: ->
    @trigger 'clean_up' # call cleanup listeners

  remove: ->
    @removeItemViews()
    super()
