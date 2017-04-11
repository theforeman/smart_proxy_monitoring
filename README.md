# Smart Proxy - Monitoring

This plug-in adds support for Monitoring to Foreman's Smart Proxy.
It requires also the Foreman Monitoring plug-in.

# Installation

Please see the Foreman manual for appropriate instructions:

* [Foreman: How to Install a Plugin](http://theforeman.org/manuals/latest/index.html#6.Plugins)

The gem name is `smart_proxy_monitoring`.

RPM users can install the `rubygem-smart_proxy_monitoring` packages.

This plug-in has not been packaged for Debian, yet.

# Configuration

The plug-in requires some configuration on the Monitoring server and the Smart Proxy.
For now the only supported Monitoring solution is Icinga 2.

## Icinga 2

The Smart Proxy connects to the Icinga 2 API using an API User with password or
certificate to get Monitoring information. It requires at least Icinga 2 version 2.5.

The Icinga project provides detailed [documentation on Icinga 2](http://docs.icinga.org/icinga2/).
The required steps for connecting the Smart Proxy and Icinga 2 will be found below.

### Monitoring Server

On the Monitoring Server you have to enable the API and create API User.

For testing the fastest way to setup this will be the following commands.

```
# icinga2 api setup
# systemctl restart icinga2.service
```

This will create the certficates, enable the API feature and create and API User `root` with
a random password. The configuration of the API User will be located in `/etc/icinga2/conf.d/api-users.conf`.

More detailed instructions:

To enable the API follow the next steps, if the API is already enabled skip this steps
and start by creating an API User. The API will already be enabled if you use the Icingaweb 2
Module Director for configuration, Icinga 2 as Agents or in a distributed or high-available
setup.

Before you can enable the API a CA and a host certificate are required, the instructions
will help you to setup Icinga 2's own CA. You can also use your Puppet's certificates or
any other CA.

To create Icinga 2's own CA run:

```
# icinga2 pki new-ca
```

Afterwards copy the CA certificate to Icinga 2's pki directory:

```
# cp /var/lib/icinga2/ca/ca.crt /etc/icinga2/pki/
```

To create a certificate request for the node run:

```
# icinga2 pki new-cert --cn $(hostname -f) --key /etc/icinga2/pki/$(hostname -f).key --csr /etc/icinga2/pki/$(hostname -f).csr
```

And then sign the certficate request to get a certificate by executing:

```
# icinga2 pki sign-csr --csr /etc/icinga2/pki/$(hostname -f).csr --cert /etc/icinga2/pki/$(hostname -f).crt
```

With the certificates created and placed in Icinga 2's pki directory you can enable the API feature.

```
# icinga2 feature enable api
# systemctl restart icinga2.service
```

To allow API connections you have to create an API User. You should name him according to the use case,
so instructions will create an user named `foreman`. 

Password authentication is easier to setup, but certificate-based authentication is more secure.

Password authentication only requires you to create an API User object in a configuration file
read by Icinga 2.

```
# vi /etc/icinga2/conf.d/api-users.conf
object ApiUser "foreman" {
  password = "foreman"
  permissions = [ "*" ]
}
# systemctl reload icinga2.service
```

Certificate-based authentication requires the API User object and a signed certificate.

```
# vi /etc/icinga2/conf.d/api-users.conf
object ApiUser "foreman" {
  client_cn = "foreman"
  permissions = [ "*" ]
}
# systemctl reload icinga2.service
# icinga2 pki new-cert --cn foreman --key /etc/icinga2/pki/foreman.key --csr /etc/icinga2/pki/foreman.csr
# icinga2 pki sign-csr --csr /etc/icinga2/pki/foreman.csr --cert /etc/icinga2/pki/foreman.crt
```

### Smart Proxy

Ensure that the Monitoring module is enabled and uses the provider monitoring_icinga2.
It is the default provider so also no setting for use_provider is fine.
If you configured hosts in Icinga2 only with hostname instead of FQDN, you can add `:strip_domain` with
all the parts to strip, e.g. `.localdomain`.

```
# vi /etc/foreman-proxy/settings.d/monitoring.yaml
---
:enabled: true
:use_provider: monitoring_icinga2
```

Configure the provider with your server details and the API User information.
Typically you will have to change the server attribute, copy the CA certificate from the server (located
in /etc/icinga2/pki/) and provide the authentication details of the API User. If using the IP address
instead of the FQDN of the server, you will have to set verify_ssl to false.

```
# vi /etc/foreman-proxy/settings.d/monitoring_icinga2.yaml
---
:enabled: true
:server: icinga2.localdomain
:api_cacert: /etc/foreman-proxy/monitoring/ca.crt
#:api_port: 5665
:api_user: foreman
:api_usercert: /etc/foreman-proxy/monitoring/foreman.crt
:api_userkey: /etc/foreman-proxy/monitoring/foreman.key
#:api_password: foreman
:verify_ssl: true
```


# TODO

Monitoring:
* Add host creation and update

Provider Icinga2:
* Add endpoint and zone management for Icinga 2 as agent

Additional Providers:
* Zabbix
* OpenNMS

# Copyright

Copyright (c) 2016 The Foreman developers

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

