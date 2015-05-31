class Submarine.Collections.TimeEntries extends Backbone.Collection
  url: ->
    if @project_id
      "/projects/#{@project_id}/time_entries"
    else if @user_id
      "/users/#{@user_id}/time_entries"
    else
      "/time_entries"

  model: Submarine.Models.TimeEntry
  project_id: null
  user_id: null
