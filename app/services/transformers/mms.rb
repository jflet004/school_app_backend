# We'll port your Apps Script logic here soon.
module Transformers
  class MMS
    # row = { "Header A"=>"val", "Header B"=>"val", ... }
    # Return a normalized Hash for preview (and later, for commit).
    def self.transform(row)
      # For now, just strip keys/values; keep as-is
      row.transform_keys { |k| k.to_s.strip }.transform_values { |v| v.is_a?(String) ? v.strip : v }
    end
  end
end
