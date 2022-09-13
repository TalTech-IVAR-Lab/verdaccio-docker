# Verdaccio Docker Bootsrapper

Quick-start repo for setting up a [Verdaccio][1] server for Unity packages inside a Docker container.


## Usage

To deploy Verdaccio, `cd` into this repo's folder and run `deploy.sh`:
```
cd verdaccio-zerotier-docker
bash deploy.sh -z YOUR_ZEROTIER_NETWORK_ID
```

After the deployment is successful, you will be able to access Verdaccio on port `4242` of your machine through `HTTP`.

[1]: https://verdaccio.org/
