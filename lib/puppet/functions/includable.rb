# @summary Test if a puppet class file exists and can be included
#
# Function to detect whether it is possible to include a given puppet class or not based on whether
# the class file exists. The intended usage of this is to allow lazy creation of role classes:
#
# @example Calling the function
#   $pp_role = $trusted['extensions']['pp_role']
#   if includable($pp_role) {
#     include $pp_role
#   } else {
#     warning("Class $pp_role was not found - falling back to role::base")
#     include role::base
#   }
# The reason for this is that Puppet deployers may want to assign roles to particular nodes without
# _immediately_ having to create the associated role class. This removes the need for up-front
# work creating role classes that are _TODO_ and the need to regenerate certificates once a suitable
# role class becomes available.
#
# Function is environment aware. There
# is an undocumented private API for puppet which could be used to hook into Puppet internals and test
# for class existance, however this API is subject to change without notice and this would entirely
# break classification if used as the example above suggests. Instead, we convert the class name into
# a string and attempt to match a regular expression defining the class inside it. If this matches the
# intention of the user was _probably_ to write a class, although we make no claims as to its validity
# and subsequent inclusion will fail if there are syntax errors.
Puppet::Functions.create_function(:'includable') do
  # @param classname Name of the class to test for incudability (existance as a file on the master)
  # @return true if `include classname` should succeed, otherwise false if the class is missing from
  #   the filesystem
  # @example Testing whether a class is defined in a file or not
  #   $foo = includable("role::base")
  #   # $foo is true if `role::base` _file_ exists in the current environment
  dispatch :includable do
    param 'String', :classname
  end

  def includable(classname)

    # convert the classname into the correct relative path:
    #   * foo -> foo/manifests/init.pp
    #   * foo::bar-> foo/manifests/bar.pp
    classpath = classname.gsub(/^([^:]+)(::)?/, '\1/manifests/').gsub('::', '/').gsub(/manifests\/$/, "init") + ".pp"

    # each environment maintains its own modulepath (from environment.conf) -
    # there is no easy way to read this so we parse it ourself

    # environment currently being evaluated `closure_scope`:
    # > In general, functions should not need access to scope; they should be
    # > written to act on their given input only. If they absolutely must look up
    # > variable values, they should do so via the closure scope (the scope where
    # > they are defined) - this is done by calling `closure_scope()`.
    # from: /opt/puppetlabs/puppet/lib/ruby/vendor_ruby/puppet/functions.rb
    environment = closure_scope.lookupvar('environment')

    # path to *ALL* environments (`/etc/puppetlabs/code/environments`)
    environmentpath = Puppet.settings.value(:environmentpath, environment)

    # path to *THIS* environment
    thisenvironmentpath = File.join(environmentpath, environment)

    # path to *THIS* environment modules
    thisenvironmentmodules = File.join(thisenvironmentpath, "modules")

    # path to *THIS* environment.conf file
    thisenvironmentconf = File.join(thisenvironmentpath, "environment.conf")


    # vendor default search path - should be
    # `/etc/puppetlabs/code/modules:/opt/puppetlabs/puppet/modules`
    basemodulepath = Puppet.settings.value(:basemodulepath, environment)

    # parse `environment.conf` for `modulepath`, falling back to puppet default
    # `modulepath` if we can't find a line
    begin

      # should yield something like: `site:modules:$basemodulepath`
      search_paths = open(thisenvironmentconf) do |f|
        f.grep(/^modulepath\s*=/)[-1].split("=")[1].strip
      end

      # replace $basemodulepath with the real basemodulepath
      search_paths = search_paths.sub('$basemodulepath', basemodulepath)
    rescue Exception => e
      # no environment.conf or not in the right format: guess the path - we
      # don't add 'site' because if its not in `environment.conf` then it really
      # shouldn't be considered
      Puppet.warning("Error reading `modulepath` from #{thisenvironmentconf} (#{e.message})")
      search_paths = "#{thisenvironmentmodules}:#{basemodulepath}"
    end


    # split each element so we can scan in order of precedence
    search_paths = search_paths.split(":")

    found = false
    i = 0

    # process each element of the search path
    while !found && i < search_paths.size
      search_path = search_paths[i]

      # protect against empty path elements
      if ! search_path.empty?
        # Search either the absolute path or prepend path for environment
        # currently being evaluated
        _search_path =
            if search_path.start_with?('/')
              search_path
            else
              File.join(thisenvironmentpath, search_path)
            end

        # figure out the exact path the the class file that should exist if the class is
        # written and ready for use. If it exists see if it contains a valid class signature
        target = "#{_search_path}/#{classpath}"
        Puppet.debug("includable checking for `#{classname}` in `#{target}`")
        if File.exists?(target) && File.open(target).grep(/^\s*class\s+#{classname}/)
          # class exists in the correct file and is _probably_ intended to be valid
          Puppet.debug("includable found `#{classname}` at `#{target}`")
          found = true
        end
      end
      i += 1
    end

    found
  end
end