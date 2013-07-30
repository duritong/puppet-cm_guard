PuppetCmGuard
=============

A puppet change management guard that includes catalog caching.

[![Build Status](https://travis-ci.org/duritong/puppet-cm_guard.png)](https://travis-ci.org/duritong/puppet-cm_guard)

Background
----------

You have a decent configuration management tool - called puppet - in place and you are managing the 
state of your infrastructure with it. But you also have an awesome platform in production, that serves
tons of happy customers, which are using it constantly and won't be happy about any interruption.

You have been wise and built your platform very modular with a lot of ways to scale it horizontally
and easy exchangeable bricks. However, your product might for example also include a lot of very long
running sessions - like phone calls - that can't be failed-over that transparently and easily. It is
therefore crucial to update your platform within multiple steps, but only after you isolated and drained
the different parts, that should be updated, to not interrupt the experience of your customers. As it
might take a while to drain the current active sessions on the bricks, you still want puppet to keep
ensuring the current state on the rest of the platform.
This means that while one part is being drained and then updated, the other parts of the infrastructure
should still being served with the "old" version of your infrastructure.

There are different ways to to build such an isolated update mechanism with puppet. One approach would
be to do implement it within your manifests, another one would be to use environments representing the
different versions.
However, both approaches have their own drawbacks, can very quickly become very confusing and complicated
and your manifests will look like a huge mess.

So time to make a step back and look at the problem from a more global perspective:

You are using puppet to easily manage tons of servers, but also to ensure that your infrastructure stays
in a certain state. This state is driven by your manifests and the puppet agents use the catalog to know
*what* they need to bring in *which* state.
The manifests can be seen as the source code for your infrastructure, the catalog is more like the binary
that represents the state for a certain node at a certain point. To be precise it's representing the state
at the compile moment.
In other words: while a snapshot of your manifests (like a git commit) can be seen as a snapshot how you
*would* have built the infrastructure at a certain point in time, a snapshot of all the catalogs are a
snapshot how you *have* built the infrastructure. Because a catalog is built with (and therefore also
contains) everything: facts, hiera values, compiled templates, collected exported resources and so on.

And this is where PuppetCmGuard enters the game: You can use it to keep serving certain clients with a
current catalog snapshot (compliance), while others will receive fresh catalogs, which might contain
resource states based on new hiera values, fresh templates or whatever you changed in your manifests.

PuppetCmGuard can be seen as a middleware, that sits between your node and the puppet compiler and uses
an invalidator to decide whether your client should get a fresh catalog or the last stored one.

As long as the invalidator does not tell the PuppetCmGuard to recompile the catalog, the PuppetCmGuard
will serve a cached - read previously compiled - catalog to the puppet client.

If no catalog has been cached so far, it will compile one whether it should compile one or not. 

Caching for the win
-------------------

Although the first goal when we came up with CmGuard, was to serve snapshots of a certain state of the
infrastructure, Brice Figureau made me aware, that CmGuard can also simply be used to cache catalogs,
without the whole idea of generating snapshots. This is a long wanted feature within the puppet community
and CmGuard is able to partially (if not even completely) address this request.
Instead of thinking infrastructure-wide about snapshots, we can also use CmGuard to simply cache our
catalog and write our own invalidator that tells puppet to recompile a catalog only if new manifests,
hiera-data or so have been pushed to your master.

As the puppetmaster will not compile a fresh catalog, this can reduce the load a lot and help you
serving more catalogs within a certain timeframe.

Invalidators
------------

The basic idea of an invalidator is, that it answers the question whether a catalog should be recompiled
or not. To make this decision it has the full request (containing the facts and so on) available. But you
can also ask your own external super service, that will provide you with more data to make your decision.
For example it would be pretty trivial to write an invalidator, that tells CmGuard to compile fresh
catalogs only on Tuesdays.


This module ships with an example invalidator called hiera_invalidator, that uses hiera to look up a key
called `update_node` to decide whether a catalog for a node should be recompiled or not. By default this
flag is set to `false`, which means that all nodes, that do not have `update_node` set to `true` within
their hiera-hierarchy, will stay on the currently cached catalog.

The dummy_invalidator is shipped to make it really painless to use this module without further
adjustements.

Both invalidators should give you a basic idea, how you could implement your own invalidator, that fits
your own criteria, when a node should be served with a fresh catalog or a cached one.

Invalidators can be shipped in your own internal module, without touching this module, they simply need to
live in `lib/puppet/cm_guard` within your module. See the next section how you can configure your own
invalidator.


Setup
-----

* Add this module to your module path. You can also install it from the forge:
    puppet module install duritong/cm_guard
* PuppetCmGuard is implemented as an indirector for the catalog. This means that you need to hook it into
   the master, by adding the following terminus to your /etc/puppet/routes.yaml file:

This should look like:

    master:
      catalog:
        terminus: compiler_cm_guard

* Additionally you can configure the different aspects of PuppetCmGuard, within
   /etc/puppet/cm_guard.yaml.

The defaults are:

    compiler: 'static_compiler' # you might change this to compiler to use the default compiler,
                                # which won't snapshot file resources
    cm_cache: 'json_cm_guard'
    invalidator: 'dummy_invalidator'
    basic_compiler: 'compiler' # you probably won't like to change this


For puppet users running still on 2.7, we use a slightly different default configuration:

* For the compiler we use `compiler` instead of `static_compiler`, as the static_compiler is not yet
  available
* For the cm_cache we use `yaml_cm_guard` instead of `json_cm_guard`, as yaml is still the default
  in 2.7

The `dummy_invalidator` does nothing than telling PuppetCmGuard to recompile the catalog each time. So using
that one won't change anything from a normal puppet master, except that your catalog will also be cached
(a second time), but this cache effectively won't be used. So you might want to use a different invalidator
(like the hiera one) or write your own (that you can ship in your own module).

Design
------

The design is pretty simple:

1. CmGuard sits in front of the compiler
1. Depending on it's cache and the answer from the invalidator it either compiles a fresh catalog or serves
   the currently cached one.
1. If serving a fresh catalog, it will cache this one for future requests in its own cache path. Why an own
   cache path? Because I did not want to pollute puppet's own internal store for catalogs with my catalog
   stuff.

Caveats
-------

* Something that is not snapshoted are plugins. So any types or other extensions won't be cached as they
  are synced before catalog compilation.

Disclaimer
----------

This extensions was developed based on my current knowledge of puppet (internals). Likely there are things
that could be done differently/better. And certainly the tests could be improved.

However, this module is battle tested and it serves the described purpose very well.

Bug reports / Pull requests (including tests) are welcome! See below.

Contributing to PuppetCmGuard
-----------------------------

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.

Copyright
---------

Copyright © 2013 mh. See LICENSE for further details.

