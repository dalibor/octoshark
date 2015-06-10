module Octoshark
  class Error < StandardError
    class NoConnection < Error; end;
    class NoCurrentConnection < Error; end;
  end
end
