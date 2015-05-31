class Submarine.Collections.ExpenseEntries extends Backbone.Collection
  url: ->
    if @project_id
      "/projects/#{@project_id}/expense_entries"
    else
      "/expense_entries"

  model: Submarine.Models.ExpenseEntry
  project_id: null
