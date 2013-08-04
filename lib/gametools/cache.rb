module GT ; end

#
# A simple cache of objects of arbitrary type. Requires that the class of
# objects this cache creates do not implement methods named +cache_free+ or
# +gt_temp_cache_source+, as these will be defined on cache object instances.
#
class GT::Cache

  #
  # The default capacity of a cache.
  #
  DEFAULT_CAPACITY  = 16
  #
  # Default initialization arguments for cache objects.
  #
  DEFAULT_INIT_ARGS = [].freeze
  #
  # The cache instance variable name, suitably long and unlikely-to-be-defined
  # for a given object.
  #
  CACHE_IVAR_NAME   = :@__gametools_temp_cache_source__

  #
  # Creates a new cache for the given +klass+. Allocates at least +capacity+
  # objects and initializes them with the provided +init_args+.
  #
  def initialize(klass, capacity: DEFAULT_CAPACITY, init_args: DEFAULT_INIT_ARGS)
    temp_self = self
    @klass = klass
    @init_args = init_args || DEFAULT_INIT_ARGS
    @objects = Array.new(capacity) { |i| __allocate_object__ }
    @reinitializer = nil
  end

  #
  # Sets a reinitializer function for cache objects. This is only called for
  # objects returned back to the cache.
  #
  def define_reinitializer(fn = nil, &block)
    @reinitializer = if block_given?
      lambda(&block)
    else
      fn
    end
  end

  #
  # Allocates an object from the cache and returns it. If no cache objects are
  # available, a new cache object is allocated and returned.
  #
  def alloc
    if @objects.empty?
      __allocate_object__
    else
      @objects.pop
    end
  end

  #
  # Returns a cache object to the cache. If the object did not already belong to
  # the cache, an exception is thrown. Additionally, if the object was already
  # returned to the cache, an exception is also thrown, as you may be handing
  # the object off to multiple owners, one of whom is working with an
  # un- or deallocated cache object.
  #
  def free(obj)
    if ! obj.gt_temp_cache_source.eql?(self)
      raise "Object does not belong to the cache trying to take it"

      # NOTE: Use Object#equal? to test if the objects are the same instance --
      # using any other comparison function (or operator) may return true when
      # the objects are only equivalent in terms of what they represent. This is
      # especially true of objects like vectors, strings, and so on that might
      # be cached and represent equal values.
    elsif @objects.any? { |cached| cached.equal?(obj) }
      raise "Double-free on cached object -- this might indicate the object had multiple owners"
    end
    @objects << obj

    # Only reinitialize an object after it's been returned to the cache. I could
    # do this on allocation, but that means keeping another ivar on the object
    # or a list of uninitialized objects, and that's not really worth the
    # trouble when I can just reinit here and be done with it.
    @reinitializer.call(obj, *@init_args) if @reinitializer
    self
  end


  private

  #
  # Allocates a new cache object and returns it.
  #
  def __allocate_object__
    @klass.new(*@init_args).tap { |instance|
      __infect_object__ instance
    }
  end

  #
  # Infects an object with the necessary methods and instance variables for it
  # to work in this cache. Should only be called from #__allocate_object__ and
  # from #initialize (for infecting existing objects provided via an existing
  # cache array or array-like object, like a Vec3Array).
  #
  def __infect_object__(instance)
    instance.instance_variable_set(CACHE_IVAR_NAME, self)

    #
    # Returns the cache object to its cache.
    #
    def instance.cache_free
      self.gt_temp_cache_source.free self
    end

    #
    # Returns the cache this object belongs to.
    #
    def instance.gt_temp_cache_source
      instance_variable_get(CACHE_IVAR_NAME)
    end
  end

end
