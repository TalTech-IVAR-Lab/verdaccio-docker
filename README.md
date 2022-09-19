# Verdaccio Docker Bootsrapper

Quick-start repo for setting up a [Verdaccio][1] server for Unity packages inside a Docker container together with [Caddy][2] proxy for automatic and easy HTTPS support.


## Usage

To deploy Verdaccio, `cd` into this repo's folder and run `deploy.sh`:
```
cd verdaccio-docker
bash deploy.sh --domain "your.npm.domain.name"
```

After the deployment is successful, you will be able to access Verdaccio on port `443` of your machine through `HTTPS`.


## CLI flags

The `deploy.sh` script has the following parameters:

- `-d, --domain` - domain name of where your registry will be hosted; this is required in order for Caddy to generate SSL certificates and enable HTTPS
- `-e, --email` - (optional) email address that Caddy will use to contact you in an unlikely case of SSL certificate auto-renewal issues

## Tips

- If you are running in the cloud (e.g. AWS, GCP), you will need to open ports `80` and `443` for the server to be accessible.

[1]: https://verdaccio.org/
[2]: https://caddyserver.com/
