#!/bin/bash
# If this file exists it will be run on the system under test before puppet runs
# to setup any prequisite test conditions, etc
mkdir -p /etc/puppetlabs/code/environments/production/modules/mock_profile2/manifests/
cat > /etc/puppetlabs/code/environments/production/modules/mock_profile2/manifests/myprofile.pp << END
class mock_profile2::myprofile() {
  file { "/tmp/mock_class_evaluated.txt":
    ensure  => file,
    owner   => "root",
    group   => "root",
    mode    => "0644",
    content => "this file should not exist - class was evaluated"
}
END

cat > /etc/puppetlabs/code/environments/production/environment.conf <<END
modulepath = site:modules:\$basemodulepath
environment_timeout = 0
config_version = '/bin/date --iso-8601'
END