# includable()
#
# Function to detect wheter it is possible to include a given puppet class or not based on whether
# the class file exists. The intended usage of this is to allow lazy creation of role classes:
#
#   $pp_role = $trusted['extensions']['pp_role']
#   if includable($pp_role) {
#     include $pp_role
#   } else {
#     warning("Class $pp_role was not found - falling back to role::base")
#     include role::base
#   }
#
# The reason for this is that Puppet deployers may want to assign roles to particular nodes without
# _immediately_ having to create the associated role class. This removes the need for up-front
# work creating role classes that are _TODO_ and the need to regenerate certificates once a suitable
# role class becomes available.
#
# Function expects code to be found at /etc/puppetlabs/code/environments and is environment aware. There
# is an undocumented private API for puppet which could be used to hook into Puppet internals and test
# for class existance, however this API is subject to change without notice and this would entirely
# break classification if used as the example above suggests. Instead, we convert the class name into
# a string and attempt to match a regular expression defining the class inside it. If this matches the
# intention of the user was _probably_ to write a class, although we make no claims as to its validity
# and subsequent inclusion will fail if there are syntax errors.
#
# @example Testing whether a class is defined in a file or not
#   $foo = includable("role::base")
#   # $foo is true if `role::base` _file_ exists in the current environment
#
Puppet::Functions.create_function(:'includable') do

  # @param classname Name of the class to test for incudability (existance as a file on the master)
  # @return true if `include classname` should succeed, otherwise false if the class is missing from
  #   the filesystem
  dispatch :includable do
    param 'String', :classname
  end

  def includable(classname)

    # convert the classname into the correct relative path:
    #   * foo -> foo/manifests/init.pp
    #   * foo::bar-> foo/manifests/bar.pp
    classpath = classname.gsub(/^([^:]+)(::)?/, '\1/manifests/').gsub('::', '/').gsub(/manifests\/$/, "init") + ".pp"

    # each environment maintains its own modulepath (from environment.conf) - ask puppet
    # what it is for the environment currently being evaluated
    search_paths = "#{Puppet.settings.value(:modulepath, Puppet.settings[:environment])}:#{Puppet.settings[:basemodulepath]}".split(":")

    found = false
    i = 0

    # process each element of the search path
    while !found && i < search_paths.size
      search_path = search_paths[i]
      if ! search_path.empty?
        # Search either the absolute path or prepend the environmentpath for the
        # environment currently being evaluated
        _search_path =
            if search_path.start_with?('/')
              search_path
            else
              File.join(Puppet.settings[:environmentpath], search_path)
            end

        # figure out the exact path the the class file that should exist if the class is
        # written and ready for use. If it exists see if it contains a valid class signature
        target = "#{_search_path}/#{classpath}"
        if File.exists?(target) && File.open(target).grep(/^\s*class\s+#{classname}/)
          # class exists in the correct file and is _probably_ intended to be valid
          found = true
        end
      end
      i += 1
    end

    found
  end
end