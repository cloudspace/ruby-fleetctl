# Fleetctl

Fleetctl is a gem for remotely controlling a fleet cluster on CoreOS. The gem executes all commands remotely on the fleet hosts via SSH, rather than using the `fleetctl` executable. At the time of this writing, this has proven to be more stable than using the native executable's `--tunnel` flag.

Warning: This gem is essentially a wrapper for an executable that is still in alpha. Things are changing rapidly. It is known to work in one specific context. Use at your own risk. Future updates will be more stable.

## Installation and Configuration

Add Fleetctl to your Gemfile (I recommend locking yourself to an exact version for now. I may change anything at any time):

    gem 'fleetctl', '0.1.2'

And `$ bundle install`

###Configure Fleetctl:

All configuration options in Fleetctl are currently global. Just pass a hash to `Fleetctl.config` with the appropriate options included, like so:

    Fleetctl.config({
      # insert configuration options here
    })

The options, with default values, are as follows:

    # a hash of global flags to be passed to the fleetctl executable.
    global: {}

    # the path to the fleetctl executable on the fleet hosts. (go ahead and move or rename it, weirdo)
    executable: 'fleetctl'

    # the logger for fleet to use. Pass it Rails.logger if you are in a rails application
    logger: Logger.new(STDOUT)

    # a string or array of strings to be prepended to the fleetctl command to be executed
    # on the remote fleet host. use this if you need to set environment variables and the like.
    command_prefix: nil

    # a discovery url to use to locate the fleet hosts.
    discovery_url: nil

    # the IP of any of the fleet hosts to use for discovery
    fleet_host: nil

    # the user to use when SSH'ing to the fleet hosts
    fleet_user: 'core'

    # options to pass varbatim to Net::SSH and Net::SCP
    ssh_options: {}

    # temp directory to be used on the fleet hosts
    remote_temp_dir: '/tmp'

At a minumum, either :fleet_host or :discovery_url must be provided in order to contact the cluster. If both are used, the discovery_url will be used as a fallback if the fleet_host specified cannot be reached.

## Usage
To use Fleetctl, first create a `Fleetctl::Controller`

A controller can be instantiated like this...

    fleet = Fleetctl.new
    => #<Fleet::Controller...>

... or you can use a global singleton instance, like so:

    fleet = Fleetctl.instance
    => #<Fleet::Controller...>

You can also call the methods `:instance`, `:machines`, `:units`, `:[]`, `:sync`, `:start`, `:submit`, `:load`, and `:destroy` on `Fleetctl` directly, and they will be passed to the singleton instance. More on them below.

In either case, Fleetctl caches its state in order to avoid repeatedly querying the cluster. When actions that would change the state are taken (such as publishing or deleting units) the cache is refreshed. In order to manually trigger a refresh, call:

    fleet.sync
    => true

To get an array of all the units on the cluster:

    fleet.units
    => [#<Fleet::Unit...>, #<Fleet::Unit...>, ...]

To get an array of all the machines that comprise the cluster:

    fleet.machines
    => [#<Fleet::Machine...>, #<Fleet::Machine...>, ...]

To get a specific unit by name:

    fleet['my-unit.service']
    => #<Fleet::Unit...>

The `:start`, `:load`, and `:submit` methods all operate on one or more `File` objects (fleet unitfiles).

    unitfile = File.open('my-unit.service')
    fleet.submit(unitfile)
    => true

To remove one or more units from the cluster, call `:destroy` on the controller, and pass in the name
or names of the units you wish to destroy

    fleet.destroy('my-unit.service')
    => true

### Working with units

A `Fleet::Unit` represents a unitfile and its accompanying docker container, if any.

### Working with machines

A `Fleet::Machine` represents a machine which is part of a fleet cluster.

#### More Documentation pending

## Contributing

1. Fork it ( https://github.com/josh-lauer/fleetctl/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
