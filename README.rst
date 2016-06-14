===============================================================
Vagrant and VirtualBox DevStack Environment for Routed Networks
===============================================================

The Vagrant file and shell scripts in this repository deploy OpenStack in a
four nodes configuration  using DevStack. The aim is to support development
and testing of Neutron's Routed Networks functionality.

The deployed nodes are:

#. An OpenStack control plane, network node and compute node, named
   ``allinone``, containing the following OpenStack services:

   * Identity.
   * Image. 
   * Compute, including control plane and hypervisor.
   * Networking, including control plane, L2 agent and L3 agent in legacy mode
     without high availabiltiy.
   * Block Storage.

#. Three compute nodes, named ``compute1``, ``compute2`` and ``compute3``,
   containing Compute hypervisors and Networking L2 agents.

During deployment, Vagrant creates the following VirtualBox networks:

#. Vagrant management network for deployment and nodes access to external
   networks such as the Internet. Becomes ``eth0`` network interface in all
   nodes.
#. Management network for the OpenStack control plane and Networking Service
   overlay networks (VXLAN). Becomes the ``eth1`` network interface in all
   nodes.
#. Physical network ``physnet1`` for VLAN type networks / segments. Becomes the
   ``eth2`` network interface in nodes ``allinone`` and ``compute1``.
#. Physical network ``physnet2`` for VLAN type networks / segments. Becomes the
   ``eth3`` network interface in nodes ``compute2`` and ``compute3``.

   .. note::
      The ``eth3`` network interface is not configured in nodes ``allinone``
      and ``compute1``. Conversely, the ``eth2`` network interface is not
      configured in nodes ``compute2`` and ``compute3``.

   .. note::
      The way physical networks ``physnet1`` and ``physnet2`` are configured
      enable the simulation of two "compute racks", the first one formed by
      nodes ``allinone`` and ``compute1`` and the second formed by nodes
      ``compute2`` and ``compute3``.

DevStack installation directory
-------------------------------

All the services enabled in DevStack are installed in ``/opt/stack``. The
``Nova`` and ``Neutron`` repositories are configured as Vagrant ``synced
folders`` with the following mapping:

.. list-table::
   :header-rows: 1
   :widths: 30 30

   * - Host machines
     - Nodes
   * - ~/nova
     - /opt/stack/nova
   * - ~/neutron
     - /opt/stack/neutron

This mapping enables the user to do all the Nova and Neutron development
activities with his / her tools of choice in the host machine, with all the
changes being reflected immediately in the nodes.

.. note::
   ``vim`` is configured in all nodes to support Python development. Besides
   having a proper ``.vimrc`` file for the ``vagrant`` account, the following
   ``vim`` plug-ins are installed and enabled:

   * `Syntastic <https://github.com/scrooloose/syntastic.git>`_ for syntax
     checking, configured with
     `Flake8 <https://flake8.readthedocs.io/en/latest>`_ for Python and pep8.
   * `SimpyFold <https://github.com/tmhedberg/SimpylFold>`_ for Python code
     folding.
   * `delimiMate <https://github.com/Raimondi/delimitMate>`_ for automatic
     closing of quotes, parenthesis, brackets, etc.

Requirements
------------

The default configuration requires approximately 10.5 GB of RAM. The amount of
resources for each node can be changed in the
``provisioning/virtualbox.conf.yml`` file.

Deployment
----------

#. Install `VirtualBox <https://www.virtualbox.org/wiki/Downloads>`_ and
   `Vagrant <https://www.vagrantup.com/downloads.html>`_.

#. Clone the ``nova`` and ``neutron`` repositories into your home directory::

     $ git clone https://git.openstack.org/openstack/nova.git
     $ git clone https://git.openstack.org/openstack/neutron.git

#. Clone this repository into your home directory and change to it::

     $ git clone https://github.com/miguellavalle/routednetworksvagrant
     $ cd routednetworksvagrant

#. Install plug-ins for Vagrant::

     $ vagrant plugin install vagrant-cachier
     $ vagrant plugin install vagrant-vbguest

#. If necessary, adjust any configuration in the
   ``provisioning/virtualbox.conf.yml`` file.

#. Launch Vagrant and grab some coffee::

     $ vagrant up

#. After the process completes, you can use the ``vagrant status`` command
   to determine the nodes status::

     $ vagrant status
     Current machine states:

     allinone              running (virtualbox)
     compute1              running (virtualbox)
     compute2              running (virtualbox)
     compute3              running (virtualbox)

#. You can access the nodes using the following commands::

     $ vagrant ssh allinone
     $ vagrant ssh compute1
     $ vagrant ssh compute2
     $ vagrant ssh compute3

#. Access OpenStack services via command-line tools on the ``allinone``
   node or via the dashboard from the host by pointing a web browser at the
   IP address of the ``allinone`` node.

   .. note::
   By default, OpenStack includes two accounts: ``admin`` and ``demo``, both
   using password ``devstack``.

#. You can save the state of the entire configuration::
     
     $ vagrant suspend

#. After completing your tasks, you can destroy the nodes::

     $ vagrant destroy
