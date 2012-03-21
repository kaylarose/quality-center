module QualityCenter
  module RemoteInterface
    class Rest
      class NotAuthenticated < RuntimeError;end
      class LoginError < RuntimeError;end
    end
  end
end
