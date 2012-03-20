module QualityCenter
  module RemoteInterface
    class Query

      def recent_events
        "http://qualitycenter.ic.ncs.com:8080/qcbin/rest/domains/{domain}/projects/{project}/event-logs"
      end

      def paging
        'page-size=10&start-index=30'
      end

      # http://qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/Content/General/Filtering.html
      def query
        "/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=1&query={detected-by[NOT(egolal)]}"
        "/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=5&query={id[1 or 2 or 3 or 4 or 5]}&order-by={last-modified[DESC]}"
        "/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=5&query={id[<10]}&order-by={last-modified[DESC]}"
        "/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=5&query={name[*SORM*]}"
      end

      # http://qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/Content/General/order-by.html
      def order
        "/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=5&query={detected-by[egolal]}&order-by={last-modified[DESC]}"
      end

    end
  end
end
