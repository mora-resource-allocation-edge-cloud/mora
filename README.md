## WARNING 

The following document could be outdated. Please refer to the 
[wiki for further information](https://github.com/mora-resource-allocation-edge-cloud/mora/wiki)

# What is this repository

_TODO_

# Micro-services/Repositories

- dash.js/
  ==> A dash.js client: it is a form from https://github.com/Dash-Industry-Forum/dash.js

- load-generator/
  ==> A load generator written in go to test the video-service edge cloud system

- metrics-collector/
  ==> the dash.js client used by the load generator will push on the apis of this micro-service information about metrics collected by looking the video

- deployment/
  ==> helm template to deploy the video service with some of the NFV docker containers

- videomanagement/
  ==> video management micro-service

- videprocessing/
  ==> micro-service to encode raw videos


# The (fake) video service provider

The video service provider consists of a MVC-based architecture with:

1. An API Gateway
1. A video management service (vms) responsible for the metadata of available video and for the HTTP/REST management of the service
1. A Mongo DB to store video metadata and authentication data
1. Two volumes: one for the raw videos and one for the encoded ones
1. A video processing service (vps) that encode the video using a strategy depending on the running variant of the video service (see below)
1. Kafka as a  message broker to make communication between the vms and the vps


## Variants

The fake video service service provider exploits the `service elasticity` mechanism as exposed in [Araldo et al.](https://dl.acm.org/doi/abs/10.1145/3341105.3374026) allowing multiple behavior of the system to be configured based on some initial configuration settings. The system is thought in order to enable Cloud-Edge offloading: the complete system is deployed on the Cloud. Instal, a partial system, can be deployed in a Edge computing scenario, so that some of the computation needed can be performed by the Edge computing nodes and "forwarded" to the cloud only when needed. We remind to reading at the paper above.

The deployment of the different configuration of the system is implemented for Kubernetes and OpenShift by exploiting
helm v3.

In particular, available variants for the deployment of the fake video service provider are:

-1. Cloud Variant: the complete system that doesn't need anything else to run. All othees variants will have to refer
one cloud variant deployment in order to work correctly; this represent the system that should be deployed at the
cloud.

0. Cache-only variant: it doesn't deploy Kafka and the vps. It's capable of only replying to GET requests. When a
   request for a video (to watch) comes to a deployment of this variant, the (cache-only) vms will check if the video metadata are available in a capped collection of its mongodb. If metadata are available (hit), the (cache-only) vms will reply with the URI for the video to be get from the cache-only variant itself. Otherwise (miss), the reply will be a redirect to the Cloud variant. A thread will be spawn to cache the Video requested in order to be ble to provide it during the next request in a LRU fashion.
1. Offline encoding variant: if adds to the previous cache-only variant, the deployment of the VPS and kafka. In
   this case, the download of the previous point is done of the raw representation of the video. The encoding of the video copy will be in the business of this variant, when a request concluded with a miss.
2. Online encoding variant: as in the offline encoding variant, a miss leads to the download of the raw
   representation of the video. In this  case, however, the encoding of the video is not persisted on the disk but is provided online when requests for that video come.

![illustration - Cloud only](https://github.com/mora-resource-allocation-edge-cloud/mora/blob//illustrations/Cloud%20only.PNG)

## Management of requests between the cloud and the edge

In order to allow users to reach the Cloud or the Edge transparently (i.e., without giving him any knowledge of the actual uris to use), a
principle similar to the one offered by the Netflix OpenConnect appliances is used. A Load balancer at the Edge is able to redirect the users
to the internal (at the edge) micro-service or the Cloud service by setting parameters as the maximum number of concurrent users that can be served by the Edge.

## How to clone the project?

```bash 
    git clone --recursive https://github.com/mora-resource-allocation-edge-cloud/mora
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

If you deploy on Minikube also set `isMinikube: true`.

# Load Generation and metrics collection

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

The load generator consumes from a queue tasks to play the videos with the Go chrome driver. It also can be set to 
expose
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
