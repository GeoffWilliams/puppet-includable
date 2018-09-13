#!/bin/bash
# If this file exists it will be run on the system under test before puppet runs
# to setup any prequisite test conditions, etc
mkdir -p /etc/puppetlabs/code/environments/production/modules/mock_profile/manifests/
cat > /etc/puppetlabs/code/environments/production/modules/mock_profile/manifests/myprofile.pp << END
class mock_profile::myprofile() {
  file { "/tmp/mock_class_evaluated.txt":
    ensure  => file,
    owner   => "root",
    group   => "root",
    mode    => "0644",
    content => "this file should not exist - class was evaluated"
}
END

rm -f /etc/puppetlabs/code/environments/production/environment.conf