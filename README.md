[![Build Status](https://travis-ci.org/GeoffWilliams/puppet-includable.svg?branch=master)](https://travis-ci.org/GeoffWilliams/puppet-includable)
# includable

#### Table of Contents

1. [Description](#description)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](REFERENCE.md)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

Provide the `includable()` function to test whether a class has been written and is in the path or not

## Usage

### includable()

Test whether the class definition for the passed in class name is exists in the environment currently
being evaluated.

For example, given:

```
/etc/puppetlabs/code/environments/production/modules/mock_profile/
└── manifests
    └── myprofile.pp


includable('mock_profile::myprofile') # true
includable('mock_profile::not_here') # false 
```

Classes will be resolved according the `modulepath` for the current environment according to Puppet. See function 
source code for exact implementation details


## Limitations
* Not supported by Puppet, Inc.

## Development

PRs accepted :)

## Testing
This module supports testing using [PDQTest](https://github.com/declarativesystems/pdqtest).


Test can be executed with:

```
bundle install
make
```

See `.travis.yml` for a working CI example
