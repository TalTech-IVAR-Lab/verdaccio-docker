# Verdaccio Docker Bootsrapper

Quick-start repo for setting up a [Verdaccio][1] server for Unity packages inside a Docker container together with [Caddy][2] proxy for automatic and easy HTTPS support.


## Usage

To deploy Verdaccio, `cd` into this repo's folder and run `deploy.sh`:
```
cd verdaccio-docker
bash deploy.sh --domain "your.npm.domain.name"
```

After the deployment is successful, you will be able to access Verdaccio on port `443` of your machine through `HTTPS`.

### CLI flags

The `deploy.sh` script has the following parameters:

- `-d, --domain` - domain name of where your registry will be hosted; this is required in order for Caddy to generate SSL certificates and enable HTTPS
- `-e, --email` - (optional) email address that Caddy will use to contact you in an unlikely case of SSL certificate auto-renewal issues

### Changing configuration

Configuration of your Verdaccio server can be changed by modifying `config.yaml` located in the root of this repository and re-deploying the server by running `deploy.sh`.
Note that running `deploy.sh` is _non-destructive_, i.e. it wil not modify/delete packages published in your current Verdaccio deployment (except updating the configuration files).
You can read more about Verdaccio's `config.yaml` file on their [official docs page][3].


## Tips

- You can use utility scripts located in the `scripts` folder of the repository to manage Verdaccio user accounts.
- If you are running in the cloud (e.g. AWS, GCP), you will need to open ports `80` and `443` for the server to be accessible (`443` is used for HTTPS access and `80` is used for automatic SSL certificate updates).

[1]: https://verdaccio.org/
[2]: https://caddyserver.com/
[3]: https://verdaccio.org/docs/configuration/
