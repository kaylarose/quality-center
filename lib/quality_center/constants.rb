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

    end

    class Query
      DIRECTIONS = %w[ASC DESC]
      DEFAULT = {
        paging: { limit: 10,   offset: 0 },
        order:  { field: 'id', direction: 'DESC' }
      }
    end

    module Mocks
      class Rest
        FIXTURES = '/home/brasca/git/qc_rest/fixtures/'
      end
    end

  end
end
