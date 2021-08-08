## WARNING 

The following document could be outdated. Please refer to the 
[wiki for further information](https://github.com/mora-resource-allocation-edge-cloud/mora/wiki)

# Micro-services/Repositories

- dash.js ==> client: it is a form from https://github.com/Dash-Industry-Forum/dash.js
- deployment/ => helm template to deploy the video service with some of the NFV docker containers
- load-generator => go load generator to test the video-service edge cloud system
- metrics-collector ==> the dash.js client used by the load generator will push on the apis of this micro-service information about metrics collected by looking the video
- videomanagement ==> video management micro-service
- videprocessing ==> micro-service to encode raw videos

# Docker environments

## Metrics collector

### docker-compose.prod.yml

/metrics-collector contains a docker-compose.prod.yml file to be run in order to get:

1. a Mongo database to store metrics
2. The API to be used by the video client to reach the mongo storage and ask for saving the metrics
3. The HTML/JS client to play videos (as a user or by the load generator capabilities)

#### Running

```bash
    docker-compose -f docker-compose.prod.yml up -d
```

```
   IMAGE                               COMMAND                  PORTS                      NAMES
   aleskandro/mora-dash-client         "/docker-entrypoint.…"   0.0.0.0:8880->80/tcp       vmc_nginx-dash-client_1
   mongo                               "docker-entrypoint.s…"   0.0.0.0:27017->27017/tcp   vmc_mongo_1
   aleskandro/mora-metrics-collector   "./service"              0.0.0.0:8080->8080/tcp     vmc_collector_1
```

### docker-compose.yml

The file docker-compose.yml is useful for development purposes. 

It will build the containers and will use volumes to mount the code within them. 

For the Golang micro-service it will also generate the swagger documentation and support live-reloading when code changes.

## Add a video in the repository
First, we will add a user "test".
Use a software like GetIt, and launch a POST request for https://cloud-vms-1.particles.dieei.unict.it:8080/vms/register
In the body, select JSON and add {"username":"test", password:"test123"}.

Now, let's add a video. First we add the metainformation. To this aim, follow the instructions above.
.....

Then, we copy and paste the id of the video whose metadata were inserted as above, and we upload the video file. To this aim, follow the instructions above.
.....

## Load Generator

The load generator is available at /load-generator.

Its Dockerfiles are dev.Dockerfile (for development) and Dockerfile (for actual use).

The code is written in Go and its configuration can be provided as environment variables. Look at the following snippet and
define your dotenv file with the variables you need to change.

```go
var (
	ServiceUrl          = getEnvString("SERVICE_URL", "http://edge-vp-1.master.particles.dieei.unict.it")
	ZipfS               = getEnvFloat64("ZIPF_S", 1.01)
	ZipfV               = getEnvFloat64("ZIPF_V", 1)
	ExpLambda           = getEnvFloat64("EXP_AVG", 0.1) // Average requests per second
	PostMetricsEndPoint = getEnvString("POST_METRICS_ENDPOINT",
		"http://video-metrics-collector.zion.alessandrodistefano.eu:8080/v1/video-reproduction")
	ClientUrl 			= getEnvString("CLIENT_URL",
		"http://video-metrics-collector.zion.alessandrodistefano.eu:8880/samples/dash-if-reference-player-api-metrics-push/index.html")
	MaxExecutionTime     = getEnvInt64("MAX_TIME_PER_REQUEST", 900)
	MaxExposedPorts 	= getEnvInt64("MAX_EXPOSED_PORTS", 1000)
)
```

The load generator consumes from a queue taks to play the videos with the Go chrome driver. It also can be set to expose
a subset of the generated tasks over the chrome remote debug protocol: just set the MaxExposedPorts to a value greater than 0.

- The ClientUrl variable is set as the url on which the video client is available;
- The ServiceUrl is set as the url on which the video server reply;
- The PostMetricsEndPoint is set to the url of the metrics server;
- The other values tune the simulation.

### Building and running the Load Generator

Two dockerfile are available:

- loadgen-chrome.Dockerfile for development purpose; you will need to mount the code as a volume if you use this container Dockerfile;
- loadgen-chrome.prod.Dockerfile is a multi-stage Docker image with the minimum requirements to run the load generator using low resources.

Example of commands to build the dev load generator:

```bash
    cd load-generator/
    docker build -t aleskandro/mora-load-generator:debug-latest . -f loadgen-chrome.Dockerfile  # Build the container
    docker run -p 9222-9350 -it -v $(pwd):/go/src/load-generator aleskandro/mora-load-generator:debug-latest bash 
```

# The (fake) video service provider

The video service provider consists of a MVC-based architecture with:

1. An API Gateway
1. A video management service (vms) responsible for the metadata of available video and for the HTTP/REST management of the service
1. A Mongo DB to store video metadata and authentication data
1. Two volumes: one for the raw videos and one for the encoded ones
1. A video processing service (vps) that encode the video using a strategy depending on the running variant of the video service (see below)
1. Kafka as a  message broker to make communication between the vms and the vps

## Variants and options

As in \[TODO put ref\], the video service provider can be configured to run as the Whole (to run as a Cloud service) 
or in part (i.e. onto the Edge) to guarantee offloading of computation and network loads.... TODO: Continue me.

The deployment of the system is implemented for Kubernetes and OpenShift by exploiting helm v3.

Three value files are available at the current time:

1. Cloud variant: All the application is run in this variant.
2. (Edge) Cache variant: it will just run the api gateway, the vms and the mongodb. When a video is asked to this service, it will  check if the video is locally available. If yes, it will reply to the user; otherwise it will redirect the user to the cloud and will  download the video from the cloud for next requests. The maximum number of available video at the edge can be set by limiting a mongo capped collection
3. (Offline) encoding variant: it will also run Kafka and the vps in order to allow the edge video service to retrieve the raw video when needed (as above) and encoding it. Also in this case, the first time a video is downloaded from the Cloud, the user will also reach the cloud to play the video. When the encoding of the video in the edge is completed, the users will play that video directly from the edge without generating any traffic to the cloud: the capped collection is set as above to retain a maximum number of videos leveraging the LRU policy to clean the 'cache'.


## Management of requests between the cloud and the edge

In order to allow users to reach the Cloud or the Edge transparently (i.e., without giving him any knowledge of the actual uris to use), a
principle similar to the one offered by the Netflix OpenConnect appliances is used. A Load balancer at the Edge is able to redirect the users
to the internal (at the edge) micro-service or the Cloud service by setting parameters as the maximum number of concurrent users that can be served by the Edge.



## Building the containers

```bash
cd videomanagement/
docker build -t aleskandro/video-server:cloud-vms -f Dockerfile.production .
cd ../
cd videprocessing
docker build -t aleskandro/video-server:cloud-vps -f Dockerfile . 

cd helm/docker/gateway
docker build -t aleskandro/video-server:cloud-gateway -f Dockerfile . 

cd helm/docker/load-balancer
docker build -t aleskandro/video-server:edge-lb -f Dockerfile .
```

## Deployment with helm

Set your values.yaml file (look at variants/*.yml and helm/vp-cloud/values.yaml) and, after the configuration of the Kuberntes/Openshift env:

```bash
helm install vp-cloud -f variants/values.cache-variant.yaml --generate-name --disable-openapi-validation
```

The last option is needed beacause some of the OpenShift objects are not part of the OpenApi specifications.


### OpenShift or Kubernetes 

If you deploy on Kubernetes you have to set in the values.yaml:

```yaml
isOpenShift: false
```

# TODOs

- **VideoProcessing**: Online-Offline encoding
- ...


# Acknowledgements and contributors

- Andrea Araldo, Telecom Sud-Paris
- Alessandro Di Stefano, University of Catania
- Antonella Di Stefano, University of Catania
- The Dash Industry Forum: https://github.com/Dash-Industry-Forum/dash.js.git 
- Students of  the distributed systems and big data 2019-2020 at the University of Catania, 
    in particular Gianluca Arena and Alex Lo Castro
