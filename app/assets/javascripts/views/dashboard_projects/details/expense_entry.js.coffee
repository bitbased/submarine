class Submarine.Views.DashboardProjectDetailsExpenseEntry extends Backbone.View
  template: JST['dashboard_projects/details/expense_entry']
  tagName: 'div'
  className: 'expense-entry-view'

  initialize: (options) ->
    @users_collection = options.users_collection
    @$el.html this.template @