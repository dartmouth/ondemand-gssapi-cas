# Open OnDemand with GSSAPI and CAS

The purpose of this repository is to document the steps necessary to deploy [Open OnDemand](https://openondemand.org/) (OOD) in an environment that uses Kerberized access control lists (ACLs) on storage and is also protected with CAS for single sign-on.

There are three steps for implementation

1. Install [mod_auth_gssapi](https://github.com/gssapi/mod_auth_gssapi) to allow for Kerberized authentication.
2. Configuration to Open OnDemand to allow for Kerberos tickets to be passed to nginx processes.
3. A second Apache installation in a Podman container that implements [mod_auth_cas](https://github.com/apereo/mod_auth_cas) and proxies connections to the first Apache.


## 1. GSSAPI Setup

## 2. Open OnDemand configuration

## 3. CAS Proxy

See [CAS-Proxy.md](./CAS-Proxy.md)

