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
            
        include QualityCenter::Defect
        defect_collection = Collection.new(connection:conn, query:query)
        puts defect_collection.flatten!.first.inspect
        # => { "id"=>"4",
               "name"=>"Some Defect",
               "creation-time"=>"2008-12-02",
               "last-modified"=>"2011-05-03 15:53:26",
               "severity"=>"2 - Major Problem",
               "detected-by"=>"somebody" }
        puts defect_collection.size
        # => 5
