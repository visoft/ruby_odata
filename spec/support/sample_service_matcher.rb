require 'uri'

module OData
  module Support
    class SampleServiceMatcher
      def self.call(req1, req2)
        regexp = /^(https?:\/\/(?:[^@]*@)?)[^:]*(:\d+\/.*$)/i
        request1 = req1.uri.match(regexp)
        request2 = req2.uri.match(regexp)

        (request1[1] == request2[1]) && (request1[2] == request2[2])
      end
    end
  end
end