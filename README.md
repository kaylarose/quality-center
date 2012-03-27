quality-center
==============

See the [API docs](http://qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/webframe.html).

Basic usage
-----------

- Create a Connection:

        require 'quality_center'
        include QualityCenter::RemoteInterface
        conn = Rest.new(user:'user', password:'secret')
     
- Construct Queries:

        query = Query.new.filter(id:'<20',severity:'2*').
                          paginate(page_size:7).
                          order_by(:last_modified, direction: 'DESC')

- Retrieve Defects:
        

        defect_collection = QualityCenter::Defect::Collection.new(connection: conn, 
                                                                  query:      query)
        defect_collection.flatten!.first
        # => { "id"            => "4",
               "name"          => "Some Defect",
               "creation-time" => "2008-12-02",
               "last-modified" => "2011-05-03 15:53:26",
               "severity"      => "2 - Major Problem",
               "detected-by"   => "somebody" }
        defect_collection.size
        # => 5
    
- Retrieve other entities (full list documented in quality\_center/constants.rb)

        conn.tasks(query:query, nice_keys:true)
        # => {:count =>50,
              :query => #<Query:0x00000003ffbc68>
              :type  =>"task",
              :entities =>
               [{"end-time"      => "2012-01-23 10:10:01",
                 "result"        => "..."
                 "passed"        => "Y",
                 "state"         => "5",
                 "type"          => "StartBuildGraph",
                 "vts"           => "2012-01-23 10:10:01",
                 "id"            => "1001",
                 "ver-stamp"     => "2",
                 "owner"         => "someuser",
                 "creation-time" => "2012-01-23 10:09:46"},
                 {...},
                 {...}
               ]

- Display friendly field labels.

        conn.tasks(query:query, nice_keys:true)
        # => {:count => 50,
              :query => #<Query:0x00000003ffbc68>
              :type  => "task",
              :entities =>
               [{"End Time"=>"2012-01-23 10:10:01",
                 "Result"        => "..."
                 "Passed"        => "Y",
                 "Task State"    => "5",
                 "Type"i         => "StartBuildGraph",
                 "Modified"      => "2012-01-23 10:10:01",
                 "Task Id"       => "1001",
                 "Version Stamp" => "2",
                 "Created By"    => "someuser",
                 "Start Time"    => "2012-01-23 10:09:46"},
                 {...},
                 {...}
               ]

- Retrieve Users.

        conn.users["Users"]["User"]
        # => [{"email"    => "User1@example.com",
               "phone"    => "+12345678901",
               "Name"     => "user1",
               "FullName" => "One, User"},
              {"email"    => Someone@example.com,
               "phone"    => "+19876543210",
               "Name"     => "someone",
               "FullName" => "Somebody, Somebody"},
              {...},
              {...}
             ]




