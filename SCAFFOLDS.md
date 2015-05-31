
# data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime  active:boolean locked_on:datetime visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float




rails g scaffold Project code:string open_date:datetime start_date:datetime focus:text due_date:datetime close_date:datetime progress:integer parent:references client:references contact:references name:string description:string  tags:text status:string notes:string        data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g scaffold Client client:references name:string tags:text details:string notes:string        data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g model ClientContact client:references contact:references        data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g scaffold Contact first_name:string last_name:string tags:text company:string title:string email:string office_number:string mobile_number:string fax_number:string notes:string shared:boolean        data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float



rails g model HarvestJob project:references harvest_id:string cache:text           data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g model HarvestClient client:references harvest_id:string cache:text       data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g model HarvestContact contact:references harvest_id:string cache:text         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g model HarvestUser user:references harvest_id:string cache:text         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float



rails g model TrelloUser user:references trello_id:string cache:text         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g model TrelloCard project:references task:references trello_id:string cache:text         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g model TrelloBoard project:references task:references trello_id:string cache:text         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float



rails g scaffold Task parent:references project:references tags:text client:references contact:references name:string status:string focus:text progress:integer notes:text open_date:datetime start_date:datetime due_date:datetime close_date:datetime         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g model ProjectParticipant project:references contact:references user:references status:string notes:text        data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g scaffold User contact:references name:string email:string notes:string password_digest:string         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g scaffold Role name:string notes:string type:string         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g model UserRole user:references role:references project:references client:references task:references        data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float



rails g model InformationAttachment information:references group:references project:references contact:references client:references user:references task:references notes:string        data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g scaffold InformationGroup name:string description:text notes:text template:text parent:references information:references primary:boolean       data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g scaffold Information parent:references primary_group:references name:string description:string tags:string template:text notes:string items:text secure_items:text security_scheme:text global:boolean       data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float



rails g model HarvestTimeEntry time_entry:references harvest_id:string harvest_project_id:string harvest_user_id:string cache:text           data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float

rails g scaffold TimeEntry base_project:references base_task:references project:references task:references billable:boolean billed:boolean date:datetime start_time:datetime end_time:datetime idle:float hours:float active_timer:datetime timers:text category:string tags:text client:references contact:references user:references status:string notes:text         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float



rails g scaffold Permalink slug:string name:string description:string destination:string         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float



### TODO ###

rails g scaffold File

rails g scaffold Dropbox name:string
rails g scaffold DropboxItem name:string description:string notes:string file:references

rails g model TaskCategory
rails g model TimeCategory
rails g model ProjectTaskCategory

rails g model Dependency #required_progress:integer, days_after, resource_availability?

rails g scaffold Workspace #public, private, primary, personal
rails g scaffold WorkspaceList #public, private, primary, personal
rails g model WorkspaceListItem  task, projet, information

rails g migration AddWorkspaceToTrelloBoard

rails g model TrelloList workspace_list:references project:references task:references trello_id:string cache:text         data:text state:string sync:text sync_time:datetime change_time:datetime history:text deleted_at:datetime archived_on:datetime active:boolean locked_on:datetime  visible:boolean audit_log:text permalog:text draft:boolean drafting:text priority:float
