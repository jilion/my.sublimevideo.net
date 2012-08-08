Zendesk API Ruby Client
=======================

Connection
----------

Basic Auth over HTTPS is currently the supported way to authenticate API requests.
(note: SSL must be enabled on the account settings page /settings/security#ssl)

```ruby
require "zendesk"

@zendesk = Zendesk::Client.new do |config|
  config.account = "https://coolcompany.zendesk.com"
  config.basic_auth "email@email.com", "password"
end
```


Collections
-----------
Collections are an implementation detail of this gem, they are Enumerable objects. The intention is to make fetching results that span across "pages"
transparent or fetching a specific page of results easily. Collections define:

  * `fetch`        - perform actual GET request manually, returns response body as JSON or XML
  * `each`         - iterate the individual results of the collection (calling `fetch` on your behalf)
  * `next_page`    - GET next page of results for that collection
  * `per_page(50)` - change the number of results for a page of results
  * `page(3)`      - GET specific page of results

Collections of resources are fetched as lazily as possible. For example `@zendesk.users` does not hit the API until it is iterated over
(by calling `each`) or until an item is asked for (e.g., `@zendesk.users[0]`).

This allows us chain methods in cool ways like:

  * `@zendesk.tickets.create({ ... data ... })`
  * `@zendesk.tickets(123).update({ ... data ... })`
  * `@zendesk.tickets(123).delete`

GET requests are not made until the last possible moment. Calling `fetch` will return the HTTP response (first looking in the cache). If you
want to avoid the cached result you can call `fetch(true)` which will force the client to update its internal cache with the latest HTTP response.

PUT (update), POST (create) and DELETE (delete) requests are fired immediately.



Users
-----

**GET**

You may fetch users individually by id

```ruby
@zendesk.users(123)                       # return user by id
@zendesk.users.current                    # currently authenticated user, (`@zendesk.users.me` is an alias)
```

all users

```ruby
@zendesk.users                            # all users in account
@zendesk.users.each {|user| ..code.. }    # iterate over requested users
@zendesk.users.per_page(100)              # all users in account (v2 should accept `?per_page=NUMBER`)
@zendesk.users.page(2)                    # all users in account (v1 currently accepts `?page=NUMBER`)
@zendesk.users.next_page                  # all users in account (v1 currently accepts `?page=NUMBER`)
```

a list of users matching criteria

```ruby
@zendesk.users("Bobo")                    # all users with name matching all or part of "Bobo"
@zendesk.users("Bobo", :role => :admin)   # all users with name matching all or part of "Bobo" who are admins
@zendesk.users(:role => :agent)           # all users who are agents
@zendesk.users(:role => "agent")          # all users who are agents
@zendesk.users(:group => 123)             # all users who are members of group id
@zendesk.users(:organization => 123)      # all users who are members of organization id
@zendesk.user(123).identities             # all identities in account for a given user
```

**POST**

A successful POST will return the created user in the response body along with a Location header with the URI to the newly created resource

```ruby
# create user from hash
@zendesk.users.create({:name => "Bobo Yodawg",
                       :email => "bc@email.com",
                       :remote_photo_url => "http://d.com/image.png",
                       :roles => 4})

# create user with block
@zendesk.users.create do |user|
  user[:name] = "Bobo Yodawg"
  user[:email] = "bc@email.com"
  user[:remote_photo_url] = "http://d.com/image.png"
  user[:roles] = 4
end
```

**PUT**

A successful PUT will return the updated user in the response body

edit user with hash

```ruby
@zendesk.users(123).update({:remote_photo_url => "yo@dawg.com"})
```

or edit user with block

```ruby
@zendesk.users(123).update do |user|
  user[:remote_photo_url] = "yo@dawg.com"
end
```

**DELETE**

```ruby
@zendesk.users(123).delete
```

**User Identities**

Users can have multiple identities. When a customer submits a ticket for the first time, their `identity` is based on the channel they submitted the ticket through.
Supported identites are `email`, `twitter`, `facebook`, `openid`, `google`.

```ruby
@zendesk.users(123).identities.create({:email => "yo@dawg.com"})
```

add a twitter handle for a user

```ruby
@zendesk.users(123).identities.create({:twitter => "yodawg"})
```

Identities that include an email address can be set to `primary` which will cause all notifications to be sent to that associated email address.

```ruby
@zendesk.users(123).identities(3).update({:primary => true})
```

Tickets
-------
All operations on tickets should be done through the tickets method. The client should hide
the complexity of "rules", "views", "requests" and be clear about what is happening.
It would be really good to work through all the best use cases and possibly add methods that
make sense for tickets, e.g., `@zendesk.tickets(1234).assign(user.id)`

**GET**

```ruby
@zendesk.tickets                                       # TODO: not supported currently
@zendesk.tickets(123)                                  # return ticket by id

@zendesk.tickets(:view => 123)                         # all tickets for view id
@zendesk.tickets(:view => "dev")                       # TODO: not supported currently

@zendesk.tickets(:tags => ["foo"])                     # all tickets with tags=foo
@zendesk.tickets(:tags => ["foo", "bar"])              # all tickets with tag=foo OR tag=bar

@zendesk.tickets(:requester => 123)                    # all tickets for requester id
@zendesk.tickets(:group => 123)                        # all tickets for group id
@zendesk.tickets(:organization => 123)                 # all tickets for organization id
@zendesk.tickets(:assignee => 123)                     # all tickets for organization id
```

**POST**

A successful POST will return the created ticket in the response body along with a Location header with the URI to the newly created resource

```ruby
# create ticket from hash
@zendesk.tickets.create({:description => "phone fell into the toilet",
                        :requester_id => 123,
                        :priority => 4,
                        :set_tags => ["phone", "toilet"]})

# create ticket with block
@zendesk.tickets.create do |ticket|
  ticket[:description] = "phone fell into the toilet"
  ticket[:requester_name] = "Snoop Dogg",
  ticket[:requester_email] = "snoop@dogg.com",
  ticket[:priority] = 4,
  ticket[:set_tags] = ["phone", "toilet"]
end
```

create a new ticket from tweet ("twicket")

```ruby
@zendesk.tickets.create({:tweet, :tweet_id => 123456})
```

**PUT**

A successful PUT will return the updated ticket in the response body

```ruby
@zendesk.tickets(123).update({:assignee_id => 321})                        # edit ticket (data passed in overrides existing)
@zendesk.tickets(123).update({:set_tags => ["foo"]})                       # adds tags to ticket
@zendesk.tickets(123).comment("my comment", {:public => true})             # adds comment to ticket
```

**DELETE**

```ruby
@zendesk.tickets(123).delete
```

Tags
----

**GET**

```ruby
@zendesk.tags                                            # 100 most used tags in the account
@zendesk.tags("foo", :type => "entry")                   # forum entries matching tag (limit 15)
@zendesk.tags("foo", :type = > "ticket")                 # tickets matching tag (limit 15)
@zendesk.tags(["foo", "bar"], :type => "ticket")         # tickets matching tag=foo OR tag=bar (limit 15)
```

Organizations
-------------
Organizations are basically `groups` for customers/requesters.

**GET**

```ruby
@zendesk.organizations                          # all organizations in account
@zendesk.organizations(123)                     # returns organization by id
@zendesk.oragnizations(123, :users => true)     # returns organization by id AND its members
```

**POST**

```ruby
# create organization from hash
@zendesk.organizations.create({:name => "Fraggle Rock"})

# create organization with block
@zendesk.organizations.create do |org|
  org[:name] = "Zoolandia"
  org[:users] = [123, 345]
end
```

**PUT**

```ruby
@zendesk.organizations(123).update({:name => "Soopa Funk"})       # edit name of organization=123
@zendesk.organizations(123).update({:users => [123, 456]})        # edit users of organization=123
```

**DELETE**

```ruby
@zendesk.organizations(123).delete
```

Groups
------
Groups are for support agents in your account. Keep in mind `organizations` are for your customers and `groups` are for your agents.

**GET**

```ruby
@zendesk.groups                                      # all organizations in account
@zendesk.groups(123)                                 # returns organization=123
@zendesk.groups(123, :users => true)                 # returns organization=123 AND its members
```

**POST**

```ruby
# create group from hash
@zendesk.groups.create({:name => "Cool People", :agents => [123, 456]})

# create group with block
@zendesk.groups.create do |group|
  group[:name] = "Cool People"
  group[:agents] = [123, 456]
end
```

**PUT**

```ruby
@zendesk.groups(123).update({:agents => [123, 456]})     # set group membership to the list of agent ids
```

remove all agents (basically setting agents to an empty set/array

```ruby
@zendesk.groups(123).update({:agents => []})
```

**DELETE**

```ruby
@zendesk.groups(123).delete
```

Forums
------
Still wresting with how to best represent forums/entries in the client library.

**GET**

```ruby
@zendesk.forums                                          # all forums in account
@zendesk.forums(123)                                     # returns forum=123
@zendesk.forums(123).entries                             # returns all entries for forum=123
```

**POST**

```ruby
# create forum from hash
@zendesk.forums.create({:name => "FAQ",
                        :description => "get your Q's A'd",
                        :locked => false,
                        :visibility => 1})

# create forum with block
@zendesk.forums.create do |forum|
  forum[:name] = "FAQ"
  forum[:description] = "get your Q's A'd"
  forum[:locked] = false
  forum[:visibility] = 1
end
```

create a new entry for a forum

```ruby
@zendesk.forums(123).entry.create({:title => "stuff",
                                   :body => "and stuff",
                                   :pinned => true,
                                   :locked => false
                                   :tags => ["foo", "bar"]})
```

**PUT**

```ruby
@zendesk.forums(123).entry(2).update(:public => false)     # edit forum entry by id
```

**DELETE**

```ruby
@zendesk.forums(123).delete
```

Ticket Fields
-------------

**GET**

```ruby
@zendesk.ticket_fields                                   # all custom ticket_fields in account
@zendesk.ticket_fields(123)                              # ticket_field with id=123
```

**POST**


**PUT**


**DELETE**



Macros
------

**GET**


**POST**


**PUT**


**DELETE**



Attachments
-----------

**GET**

**POST**

**PUT**

**DELETE**



Search
------

**GET**


**POST**


**PUT**


**DELETE**



Contributing
------------
Contribution is encouraged and will be acknowledged in the gem's contributor's list. Everyone will know you helped and it will rock.

Ways you can help:

  * report bugs
  * writing/fixing documentation
  * writing specifications (provide suggestions for API v2)
  * writing code (refactoring, strengthening areas that are weak, catching typos)

Note on Patches/Pull Requests
-----------------------------
  * Fork the project.
  * Make your feature addition or bug fix.
  * Add tests for it. This is important so we don't break it in a future version unintentionally.
  * Commit
  * Send a pull request. Bonus points for topic branches.

MIT License
-----------
Copyright (c) 2011 Zendesk

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
