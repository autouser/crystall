Crystall is a simple Project/Ticket REST API.

## Instalation

Fork it if you wish, clone it from Github, enter the directory. Then execute in a shell the commands below.

```
bundle
rake db:migrate
rails s
```

Or just deploy it with a deployment system.

## Resources

Crystall defines next resources.

#### User

There are three types of users:

* **admin** - can create, read, update and delete everething in the system.
* **user** - can create a new user, project or ticket; can read any project or ticket ; can read and destroy his registration only.
* **guest** - can create a new user; can can read any project or ticket; don't need an authentication.

You can access *users* resources:

```
# Get list of users.
# Authentication is required. Only admin is allowed.
GET /api/v1/users.json

# Get a user by id.
# Authentication is required. Admin allowed to get any user, user - only himself.
GET /api/v1/users/1.json 

# Create a new user.
# Authentication isn't required. Any admin, user or guest can create a new user.
POST /api/v1/users.json

# Update an existing user by id.
# Authentication is required. Admin allowed to update any user, user - only himself.
PUT /api/v1/users/1.json

# Destroy an existing user by id.
# Authentication is required. Admin allowed to destroy any user, user - only himself.
DELETE /api/v1/users/1.json
```

#### Project

Provides with information about a project. Has fields:

* **name** - required
* **description** - optional
* **status** - required. can be 'open' or 'closed'

You can access *projects* resources:

```
# Get list of projects.
# Authentication isn't required. Any admin, user or guest can get a projects list.
GET /api/v1/projects.json

# Get a projects by id.
# Authentication isn't required. Any admin, user or guest can get a project.
GET /api/v1/projects/1.json 

# Create a new project.
# Authentication is required. Only admin and user can create a new project.
POST /api/v1/projects.json

# Update an existing project by id.
# Authentication is required. Admin allowed to update any project, user - only owned by him.
PUT /api/v1/projects/1.json

# Destroy an existing project by id.
# Authentication is required. Admin allowed to destroy any project, user - only owned by him..
DELETE /api/v1/projects/1.json
```

#### Ticket

Provides with information about a project's ticket. Has fields:

* **subject** - optional
* **content** - required
* **status** - required. can be 'open', 'closed' or 'finished'

You can access *projects* resources:

```
# Get list of tickets.
# Authentication isn't required. Any admin, user or guest can get a tickets list.
GET /api/v1/projects/1/tickets.json

# Get a tiket by id.
# Authentication isn't required. Any admin, user or guest can get a ticket.
GET /api/v1/projects/1/ticket/1.json 

# Create a new ticket.
# Authentication is required. Only admin and user can create a new ticket.
# User can't create a ticket if project is in 'closed' state and user isn't project owner.
POST /api/v1/projects/1/tickets/1.json

# Update an existing ticket by id.
# Authentication is required. Admin allowed to update any project, user - only owned by him.
# User can't update a ticket if project is in 'closed' state and user isn't project owner.
PUT /api/v1/projects/1/tickets/1.json

# Destroy an existing ticket by id.
# Authentication is required. Admin allowed to destroy any ticket, user - only owned by him..
DELETE /api/v1/projects/1./tickets/1.json
```

Every resource field must be prepended with namespace. E.g. `user[username]` or `ticket[subject]`

## Authentication

Crystall uses HTTP Basic Authentication to provide access to all entities. Don't forget to use it in your JS code, e.g:

```
$.ajaxSetup({
    headers: { "Authorization" : "Basic " + btoa('admin' + ":" + 'test1234') }
});

$.ajax({
  method: 'GET', 
  url: "http://localhost:3000/api/v1/users.json",
}).done(function(r) {
  // do something
});
```

