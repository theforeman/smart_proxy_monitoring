# Smart Proxy - Monitoring

This plug-in adds support for Monitoring to Foreman's Smart Proxy.
It requires also the Foreman Monitoring plug-in.

# Installation

Please see the Foreman manual for appropriate instructions:

* [Foreman: How to Install a Proxy Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Smart-Proxy_Plugin)

The gem name is `smart_proxy_monitoring`.

RPM users can install the `rubygem-smart_proxy_monitoring` packages.

Deb users can install the `ruby-smart-proxy-monitoring` packages.

# Configuration

The plug-in requires some configuration on the Monitoring server and the Smart Proxy.
For now the only supported Monitoring solution is Icinga 2 and the combination of Icinga 2
and the Icinga Web 2 Module Director.

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

Afterwards copy the CA certificate to Icinga 2's pki directory (depending on installation
source and platform you have to create the pki directory first with write permissions for the
user Icinga 2 is running with, typically `icinga` or `nagios`):

```
# install -o icinga -g icinga -m 0775 -d /etc/icinga2/pki
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

In addition to the authentication a Host template is required. By default it uses "foreman-host" if none
is provided from the Foreman WebUI. This template should define defaults for the host check and intervals.

```
# vi /etc/icinga2/conf.d/templates.conf
template Host "foreman-host" {
    check_command = "hostalive"
    max_check_attempts = "3"
    check_interval = 5m
    retry_interval = 1m
    enable_notifications = true
    enable_active_checks = true
    enable_passive_checks = true
    enable_event_handler = true
    enable_perfdata = true
    volatile = false
}
```

### Smart Proxy

Ensure that the Monitoring module is enabled and uses the provider monitoring_icinga2.
It is the default provider so also no setting for use_provider is fine.
If you configured hosts in Icinga2 only with hostname instead of FQDN, you can add `:strip_domain` with
all the parts to strip, e.g. `.localdomain`.
By default, SmartProxy will collect monitoring statuses from your monitoring solution and upload them to
Foreman. This can be disabled by setting `collect_status` to `false`.

```
# vi /etc/foreman-proxy/settings.d/monitoring.yml
---
:enabled: true
:use_provider: monitoring_icinga2
:collect_status: true
```

Configure the provider with your server details and the API User information.
Typically you will have to change the server attribute, copy the CA certificate from the server (located
in /etc/icinga2/pki/) and provide the authentication details of the API User. If using the IP address
instead of the FQDN of the server, you will have to set verify_ssl to false.

```
# vi /etc/foreman-proxy/settings.d/monitoring_icinga2.yml
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

Afterwards restart the service.

```
# systemctl restart foreman-proxy.service
```

## Icinga 2 and Icinga Web 2 Module Director

This requires you to do the configuration steps above so
Downtimes could be send to and Status information could be
read from Icinga 2.

In addition you have to configure the provider Icingadirector
for managing hosts in the Icinga Web 2 Module Director. This
graphical configuration frontend for Icinga 2 will allow you
to customize the host, e.g.  adding additional required objects
for using Icinga 2 as a monitoring agent or assign more attributes
and services. By default it requires a template named `foreman-host`.

### Icinga Web 2 Module Director

Using the API of the Icinga Web 2 Module Director requires
Authentication and Authorisation like it is described in its
[documentation](https://github.com/Icinga/icingaweb2-module-director/blob/master/doc/70-REST-API.md).

For the basic authentication of the webserver there are two
possible ways of configuration. If you already use basic auth
simply add a user and password to the authentication source.
If you do not want to add basic authentication you can configure
the webserver to auto login as a user depending on your source ip.
```
# vi /etc/httpd/conf.d/icingaweb2.conf
...
RewriteBase /icingaweb2/
RewriteCond %{REMOTE_ADDR} ^192\.168\.142\.3
RewriteRule ^(.*)$ - [E=REMOTE_USER:foreman]
...
```

In Icinga Web 2 you also have to add an authentication backend
"external".
```
# vi /etc/icingaweb2/authentication.ini
[External]
backend = "external"
```

Furthermore a role is required assigning permissions to your user.
```
# vi /etc/icingaweb2/roles.ini
[Foreman]
users = "foreman"
permissions = "module/director, director/api, director/*"
```

### Smart Proxy

Ensure that the Monitoring module is enabled and uses the provider monitoring_icinga2
and monitoring_icingadirector.
```
# vi /etc/foreman-proxy/settings.d/monitoring.yml
---
:enabled: true
:use_provider:
 - monitoring_icinga2
 - monitoring_icingadirector
```

Configure the provider with the location of your director installation and
the User information if required. Using SSL with verification is recommended
but not required.
```
---
:enabled: true

:director_url: https://www.example.com/icingaweb2/director
:director_cacert: /etc/foreman-proxy/monitoring/ca.crt
:director_user: foreman
:director_password: foreman
:verify_ssl: true
```

Afterwards restart the service.

```
# systemctl restart foreman-proxy.service
```

# Troubleshooting

The plug-in uses the configuration of the Smart Proxy to write its logs and does
not provide a seperate log for now. So have a look into `/var/log/foreman-proxy/proxy.log`
for default installations.

Also look into the logs of the monitoring solution and when opening issues attach relevant entries
for both logs. For Icinga 2 it is typically `/var/log/icinga2/icinga2.log` or if enabled
`/var/log/icinga2/debug.log`. Icinga Web 2 Director uses Icinga Web 2's configuration
which is typically logging to syslog with faciltiy `user` and application prefix `icingaweb2`
which will result in logging entry in `/var/log/message` for osfamily Red Hat and `/var/log/syslog`
for osfamily Debian.

# TODO

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

