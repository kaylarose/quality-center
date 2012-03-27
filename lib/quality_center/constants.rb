module QualityCenter

  class Parser
    DATE_FIELDS = %w[closing-date creation-time last-modified]
    USER_FIELDS = %w[detected-by owner]
  end

  module RemoteInterface

    class Rest
      BASE_URI = 'qualitycenter.ic.ncs.com:8080'
      AUTH_URI = {
        get:  '/qcbin/authentication-point/login.jsp',
        post: '/qcbin/authentication-point/j_spring_security_check'
      }
      PREFIX   = '/qcbin/rest'
      DEFECTS  = '/domains/TEST/projects/AssessmentQualityGroup/defects'
      DOMAIN   = 'TEST'
      PROJECT  = 'AssessmentQualityGroup'
      SCOPE    = "/domains/#{DOMAIN}/projects/#{PROJECT}"
      ENTITIES = %w[ defects favorites releases resources requirements tests 
                     tasks task-logs release-cycles results test-sets 
                     test-set-folders test-instances analysis-items 
                     dashboard-pages dashboard-folders test-configs ]
    end

    class Query
      DIRECTIONS = %w[ASC DESC]
      DEFAULT = {
        paging: { 'page-size' => 10,   'start-index' => 1 },
        order:  { 'field'     => 'id', 'direction'   =>'DESC' }
      }
    end

    module Mocks
      class Rest
        FIXTURES = '/home/brasca/git/qc_rest/fixtures/'
      end
    end

  end
end
