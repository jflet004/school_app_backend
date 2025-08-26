# Roo sometimes looks for Roo::Base::Fixnum / Bignum on newer Rubies.
# Alias them to Integer if they aren't defined.
if defined?(Roo) && defined?(Roo::Base)
  Roo::Base.const_set(:Fixnum, Integer) unless Roo::Base.const_defined?(:Fixnum)
  Roo::Base.const_set(:Bignum, Integer) unless Roo::Base.const_defined?(:Bignum)
end
