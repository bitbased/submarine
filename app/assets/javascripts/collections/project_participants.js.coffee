class Submarine.Collections.ProjectParticipants extends Backbone.Collection
  url: ->
    if @project_id
      "/projects/#{@project_id}/project_participants"
    else
      "/project_participants"

  model: Submarine.Models.ProjectParticipant
  project_id: null