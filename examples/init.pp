# @PDQTest

if includable("mock_profile::myprofile") {
  $class_exists = "class exists"
} else {
  $class_exists = "class missing"
}

if includable("mock_profile::missing_profile") {
  $class_missing = "class exists"
} else {
  $class_missing = "class missing"
}

file { "/tmp/class_exists.txt":
  ensure => file,
  owner => "root",
  group => "root",
  mode => "0644",
  content => $class_exists,
}

file { "/tmp/class_missing.txt":
  ensure => file,
  owner => "root",
  group => "root",
  mode => "0644",
  content => $class_missing,
}