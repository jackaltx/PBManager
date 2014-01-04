# PBManager

This is a port of the puppetlabs vagrant bootstrapper.

I am a kinesthetic learner, which means I learn by failing. At this time it is more
pedagogical exercise than anything useful.

What I need for my next area of resarch is a way to take a "pristine linux ISO", install the provisioner, then
allow it to properly provisioned for its purpose when I want one..

This works in two phases:

First it builds an ISO to be used.  This is done by taking a "clean install iso", then adding some puppet git stuff and some
linux kickstart stuff.  Second it uses vagrant to assembly a vm from that ISO.  That vm is then converted to and OVF
for importing to VMWARE.

I have only been working on the Centos side, debian is broken, came to me that way.

I have started the work of separating out the data from the functionality. the functionality will be stored in the
config directory.

It will be a gem.  That is the my next exercise, but it was easier to just run from the development ditrectory.
Currently there are no tests (really have not got that process down well enough that is does not drag the coding out.)
It executed out of a rake task on a Fedora distro using an environment variable set by "setup_symbols.sh".

I have only tested it on my Fedora 20 development box.  I will likely test on a Centos 6.4 next.
I don't have an inventroy of the rpm's required. It would be nice to get a "puppet module" that prepare the development
machine, but that is overkill.



## Installation

NOT YET READY FOR THIS PART. THE HARNESS IS HERE, WAITING FOR TIME FOR ME TO LEARN HOW TO DO IT.

Add this line to your application's Gemfile:

    gem 'PBManager'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install PBManager

## Usage

(This is temporary)

go to where you have downloaded and set the environment variable.  Note: it will not work without it.

    $ cd <source directory>
    $ . setup_symbols

To create the iso

    $ rake createiso

then you can create ths ISO

    $ rake createvm

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
