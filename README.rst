===============================================================
Vagrant and VirtualBox DevStack Environment for Routed Networks
===============================================================

The Vagrant file and shell scripts in this repo deploy OpenStack in a three
node configuration  using DevStack. The aim is to supppor development and
testing of Neutron's Routed Networks functionality.

The deployed nodes are:

#. A control plane and compute node, named ``allinone``, containing the
   following OpenStack services:

   * Identity.
   * Image. 
   * Compute, including control plane and hypervisor.
   * Networking, including control plane, L2 agent and L3 agent in legacy mode
     without high availabiltiy.
   * Block Storage.

#. Two compute nodes, named ``compute1`` and ``compute2``, containing Compute
   hypervisors and Networking L2 agents.

During deployment, Vagrant creates the following VirtualBox networks:

#. Vagrant management network for deployment and VM access to external
   networks such as the Internet. Becomes ``eth0`` network interface in all
   nodes.
#. Management network for the OpenStack control plane and Networking Service
   overlay networks (VXLAN). Becomes the ``eth1`` network interface in all
   nodes.
#. Physical network ``physnet1`` for VLAN type networks / segments. Becomes the
   ``eth2`` network interface in nodes ``allinone`` and ``compute1``.
#. Physical network ``physnet2`` for VLAN type networks / segments. Becomes the
   ``eth3`` network interface in nodes ``allinone`` and ``compute2``.

   .. note::
      The ``eth2`` network interface is not configured in node ``compute2``.

   .. note::
      The way physical networks ``physnet1`` and ``physnet2`` enable the
      simulation of two "compute racks", the first one formed by nodes
      ``allinone`` and ``compute1`` and the second formed by nodes ``allinone``
      and ``compute2``.

DevStack installation directory
-------------------------------

All the services enabled in DevStack are installed in ``/opt/stack``. The
``Nova`` and ``Neutron`` repositories are configured as Vagrant ``synced
folders`` with the following mapping:

.. list-table::
   :header-rows: 1
   :widths: 30 30

   * - Host machines
     - VMs
   * - ~/nova
     - /opt/stack/nova
   * - ~/neutron
     - /opt/stack/neutron

This mapping enables the user to do all the Nova and Neutron development
activities with his / her tools of choice in the host machine, with all the
changes being reflected immediately in the VMs.

Requirements
------------

The default configuration requires approximately 9 GB of RAM. The amount of
resources for each VM can be changed in the
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

#. Launch the VMs and grab some coffee::

     $ vagrant up

#. After the process completes, you can use the ``vagrant status`` command
   to determine the VM status::

     $ vagrant status
     Current machine states:

     allinone              running (virtualbox)
     compute1              running (virtualbox)
     compute2              running (virtualbox)

#. You can access the VMs using the following commands::

     $ vagrant ssh allinone
     $ vagrant ssh compute1
     $ vagrant ssh compute2

#. Access OpenStack services via command-line tools on the ``allinone``
   node or via the dashboard from the host by pointing a web browser at the
   IP address of the ``allinone`` node.

   Note: By default, OpenStack includes two accounts: ``admin`` and ``demo``,
         both using password ``devstack``.

#. You can save the states of the VM::
     
     $ vagrant suspend

#. After completing your tasks, you can destroy the VMs::

     $ vagrant destroy
