# sinkholed

A sinkhole for collecting and analysing malicious traffic.

This software package contains a server with a plugin interface so that it can easily be extended to support sinkholing virtually any protocol, run analysis on obtained malware samples or traffic, and store findings and other metadata in any data storage backend of your choosing.

By default sinkholed comes with the following plugins:

- an smtp input plugin for consuming email traffic
- a simple file storage backend configured to use a mounted docker volume to store obtained malware samples
- an elasticsearch plugin used to store information about each event and accompanying metadata

**Table of contents:**

* [sinkholed](#sinkholed)
  * [Wtf is this for?](#wtf-is-this-for)
  * [Try it out using docker-compose](#try-it-out-using-docker-compose)
  * [Generating a JWT secret](#generating-a-jwt-secret)
  * [sinkholed development](#sinkholed-development)
     * [Plugin development](#plugin-development)
  * [Configuration](#configuration)
     * [Config file](#config-file)
     * [Configuring plugins](#configuring-plugins)
     * [Configuring the JWT secret](#configuring-the-jwt-secret)
  * [Deploying using docker](#deploying-using-docker)
     * [Using docker](#using-docker)
     * [Running the build](#running-the-build)
  * [Deploying without docker](#deploying-without-docker)
     * [Building](#building)
     * [Installing](#installing)
  * [Deploying to AWS](#deploying-to-aws)
  * [Command line reference](#command-line-reference)
     * [sinkholed](#sinkholed-1)
     * [sinkholecli](#sinkholecli)
  * [REST API reference](#rest-api-reference)
  * [Plugin API reference](#plugin-api-reference)
  * [Godoc documentation](#Godoc-documentation)


## Wtf is this for?
This is for anyone who wants to sinkhole malware traffic in their lab and run analysis and collect samples. I use it as an SMTP server which I can route outbound traffic to instead of the internet and collect all spam email leaving my lab. The SMTP server is simply an [upstream plugin](https://github.com/scrapbird/sinkholed/blob/master/docs/plugins.md#upstreamplugin) that pipes [events](https://github.com/scrapbird/sinkholed/blob/master/docs/plugins.md#the-event-object) into sinkholed to be processed. Through this method you can extend sinkholed to support any protocol.


## Try it out using docker-compose

The fastest way to get sinkholed up and running locally is with `docker-compose`. The only configuration you will need to do is generate a JWT secret for the sinkholed API. You can do this with the `sinkholecli` tool. See [Generating a JWT secret](#Generating-a-JWT-secret) for instructions.

You will also need to ensure that your `vm.max_map_count` is set to a high enough value or elasticsearch will not run: `sudo sysctl -w vm.max_map_count=262144`

Next, simply run `docker-compose up` to bring elasticsearch, kibana and sinkholed online. With default plugins loaded you should now be able to route smtp traffic to `localhost:1337` and access the sinkholed [API](docs/api.md) on `localhost:8080`.


## Generating a JWT secret

If you have go installed on your machine you can build sinkholecli by running `./build.sh sinkholecli`. This will run the build script and tell it to only build `sinkholecli` rather than the whole package.

Next run `echo "SINKHOLED_JWTSECRET=$(./bin/sinkholecli gensecret)" > .env` to generate a JWT secret and populate your `.env` file with it. This `.env` file is used by `docker-compose` to set the environment variables for sinkholed.

> *Note*: if you do not have go installed on your machine you can still run the `sinkholecli` tool using docker:
>
> Build the sinkholed container: `docker-compose build sinkholed`. Or if you don't want to use docker-compose: `docker build -f Dockerfile.dev -t sinkholed_sinkholed .`
>
> You can now build and run the `sinkholecli` tool from inside the docker container:
>
> ```bash
> docker run --entrypoint bash -it -v `pwd`:/opt/sinkholed -v sinkholed_gomods:/root/go/pkg/mod sinkholed_sinkholed:latest
> # You should now be in a shell inside the docker container
> ./build.sh sinkholecli
> ./bin/sinkholecli gensecret
> ```
>
> Now you can manually paste your secret inside the `.env` file


## sinkholed development

To ease development of both sinkholed and it's plugins the [docker-compose.yml](docker-compose.yml) file configures `docker-compose` to mount the project directory inside the container at `/opt/sinkholed`. The docker [entrypoint](entrypoint.sh) script will run the [build](build.sh) script to build sinkholed before launching. This means that you can make changes directly to the source code and simply run `docker-compose stop sinkholed && docker-compose start sinkholed` to rebuild and restart the server.

### Plugin development

Instructions on developing sinkholed plugins can be found in the [plugin documentation](docs/plugins.md).


## Configuration

### Config file

The sinkholed config file is a yaml file that by default lives in `/etc/sinkholed/sinkholed.yml`. You can launch sinkholed with a different config file by passing it the `-config` flag. The config file can have the following values:


| Config var  | Description                                                                |
| -           | -                                                                          |
| ListenAddr  | The address to bind the API to, in the format: `host:port`                 |
| LogPath     | Path to the log file                                                       |
| LogLevel    | Threshold to be met before a log event is logged                           |
| PluginsPath | The directory to look for plugin files in                                  |
| Plugins     | A map of plugin config objects, using the plugin file name minus the `.so` |

### Configuring plugins

Please see the section on configuring plugins in the [plugin documentation](https://github.com/scrapbird/sinkholed/blob/master/docs/plugins.md#plugin-configuration).


### Configuring the JWT secret

The JWT secret is passed to sinkholed as an environment variable: `SINKHOLED_JWTSECRET`. See the [Generating a JWT secret](#Generating-a-JWT-secret) section for instructions. Ensure that this variable is exported into your environment before launching sinkholed.


## Deploying using docker

### Using docker

To build a production release, install any plugins required into the [plugins/](plugins/) directory, modify [config/sinkholed.yml](config/sinkholed.yml) to your desired configuration and run `docker build -t sinkholed .`

### Running the build

As the config file is packaged into the docker container by default you can simply run the build however you like, making sure to pass the `SINKHOLED_JWTSECRET` environment variable so that you can authenticate to the API.

If you would like to override the config file in the container, simply mount a different one to `/etc/sinkholed/sinkholed.yml` when you run your container.


## Deploying without docker

### Building

Build sinkholed using the [build.sh](build.sh) script. This will build all plugins located in the [plugins/](plugins/) directory and then build sinkholed and sinkholecli. All binaries will be placed in a `bin/` directory in the root of the project repo.

When building sinkholed without making any changes to the plugins you should see the following files in the `bin/` directory:

- elasticsearch.so
- samplefs.so
- sinkholecli
- sinkholed
- smtpd.so

### Installing

You can install `sinkholed` and its accompanying plugins wherever you like. Here is an example installation:

- elasticsearch.so: `/usr/local/lib/sinkholed/elasticsearch.so`
- samplefs.so: `/usr/local/lib/sinkholed/samplefs.so`
- smtpd.so: `/usr/local/lib/sinkholed/smtpd.so`
- sinkholecli: `/usr/local/bin/sinkholecli`
- sinkholed: `/usr/local/bin/sinkholed`

And here is an accompanying config file, placed in `/etc/sinkholed/sinkholed.yml` that uses the above install locations:

```yaml
---
## sinkholed example config
#
# Please provide the JWT secret key as an environment variable named SINKHOLED_JWTSECRET

# Address to bind API to
# note: this is inside the docker container, we aren't binding to all adapters on host
ListenAddr: 0.0.0.0:8080

# Path to log to
LogPath: /var/log/sinkholed.log
# Log level
LogLevel: info

# Plugins to load
PluginsPath: /usr/local/lib/sinkholed
Plugins:
  "elasticsearch":
    Addresses:
      - http://elasticsearch:9200
  "smtpd":
    ListenAddress: 0.0.0.0:1337
  "samplefs":
    DestDir: /var/lib/sinkholed/samples
```


## Deploying to AWS

Terraform templates are available to bring up a full production ready environment to run sinkholed. The templates will create an ECS service and cluster to run sinkholed, elasticsearch cluster and configure a load balancer all inside a dedicated VPC. By default this setup takes advantage of the free tiers of everything created and should cost nothing to run depending on data storage use.

More information can be found in the [terraform readme](terraform/README.md).


## Command line reference

### sinkholed 

Usage of `./bin/sinkholed`:

| CLI arg        | Description                                          |
| -              | -                                                    |
| -config string | Config file (default "/etc/sinkholed/sinkholed.yml") |
        

### sinkholecli

Usage of `./bin/sinkholecli`:

**Subcommands:**

| Subcommand | Description                                                            |
| -          | -                                                                      |
| gensecret  | Generates the secret key to be used to sign and verify JWT auth tokens |
| genjwt     | Generate a JWT for a client to use to authenticate to the API          |

Usage of `./bin/sinkholecli gensecret`:

| CLI arg     | Description                           |
| -           | -                                     |
| -length int | Length of the JWT secret (default 64) |
        
Usage of `./bin/sinkholecli genjwt`:

*Note:* Requires the `SINKHOLED_JWTSECRET` environment variable to be set.

| CLI arg        | Description                                          |
| -              | -                                                    |
| -config string | Config file (default "/etc/sinkholed/sinkholed.yml") |
| -length int    | Number of days until the JWT expires, 0 for never    |


## REST API reference

Information about the REST API can be found in the [REST API Documentation](docs/api.md).


## Plugin API reference

Information about the plugin API can be found in the [Plugin API Documentation](docs/plugins.md).

## Godoc documentation

Full godoc.org documentation is available at: [https://godoc.org/github.com/scrapbird/sinkholed](https://godoc.org/github.com/scrapbird/sinkholed).

