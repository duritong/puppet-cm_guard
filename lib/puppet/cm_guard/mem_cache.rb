# This is an extension to any of the catalogs stores,
# that will keep a catalog also cached in memory to not have to
# deserialize it on each request.
# It will use a simple timestamp file to keep the catalog cache
# consistent amongst different puppet processes, as reading a one
# line yaml file is much faster than a catalog that can go up to
# multiple megabytes.
module Puppet::CmGuard
  module MemCache
    
    def find(request)
      # do we have a current catalog cached in memory
      unless catalog = current_cache(request.key)
        # do we have a catalog cached on disk with a timestamp? -> cache the catalog in memory
        if (catalog = super(request)) && (curr_timestamp = read_timestamp(request.key))
          cache_catalog(request.key, catalog, curr_timestamp)
        end
      end
      catalog
    end
    
    def save(request)
      res = super(request)
      # cache the catalog with the current timestamp
      cache_catalog(request.key, request.instance, save_timestamp(request.key))
      res
    end
    
    protected
    
    def cache_catalog(key, catalog, timestamp)
      mem_cache[key] = {
        :timestamp => timestamp,
        :catalog   => catalog
      } 
    end
    
    def current_cache(key)
      # do we have a current catalog in the mem_cache?
      if mem_cache[key] && mem_cache[key][:catalog] && mem_cache[key][:timestamp]
        return mem_cache[key][:catalog] if read_timestamp(key) == mem_cache[key][:timestamp]
      end
      nil
    end
    
    def read_timestamp(key)
      f = timestamp_path(key)
      File.exists?(f) ? read_timestamp_file(f) : nil
    end
    def read_timestamp_file(file)
      (YAML.load_file(file)||{})['timestamp']
    end

    def save_timestamp(key)
      now = Time.now
      Puppet::Util.replace_file(timestamp_path(key), 0640) do |file|
        file.print YAML.dump({'timestamp' => now})
      end
      now
    end

    def timestamp_path(name)
      path(name,'.timestamp')
    end

    def mem_cache
      @mem_cache ||= {}
    end

    # our own caching path to not interfere with std. caching
    def path(name,ext=nil)
      a,filename = File.split(ext.nil? ? super(name) : super(name,ext))
      a,b = File.split(a)
      File.join(a,'catalog_cm_guard',filename)
    end
  end
end
