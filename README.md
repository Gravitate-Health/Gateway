
Gravitate Health Gateway: Express Gateway
=================================================

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Table of contents
-----------------

- [Gravitate Health Gateway: Express Gateway](#gravitate-health-gateway-express-gateway)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Installation](#installation)
    - [Local installation](#local-installation)
    - [Kubernetes deployment](#kubernetes-deployment)
      - [Expose the gateway to the outside of the cluster](#expose-the-gateway-to-the-outside-of-the-cluster)
  - [Usage](#usage)
    - [Basic operation](#basic-operation)
    - [Additional options](#additional-options)
  - [Known issues and limitations](#known-issues-and-limitations)
  - [Getting help](#getting-help)
  - [Contributing](#contributing)
  - [License](#license)
  - [Authors and history](#authors-and-history)
  - [Acknowledgments](#acknowledgments)

Introduction
------------

[Express Gateway](https://github.com/ExpressGateway/express-gateway) is a microservices API gateway implemented using Express.js, it allows the dynamic addition of new services to the gateway without the need of restarting the service, using its admin [API](https://www.express-gateway.io/docs/admin/). 

This repository contains the files needed for the compilation of the Gravitate Health Gateway, implemented using the Express Gateway framework. It also contains the files for its deployment in a Kubernetes cluster, as well as the instructions to be followed. As the gateway implements a JWT auth scheme using OIDC ([Keycloak](https://github.com/keycloak/keycloak)) the instructions for the procurement of the token will also be provided.

Installation
------------

The gateway can be installed in two possible ways, a local installation and a Kubernetes deployment. The local one should be only used for testing, or middleware development.

### Local installation

For the local deployment first clone this repository and cd into it:

```bash
git clone <repo>
cd gateway
```

After that you can change the files [gateway.config.yml](config/gateway.config.yml) and [system.config.yml](config/system.config.yml) to fit your testing needs. Once done that, install the dependencies and run using NPM:

```bash
npm install
npm start
```

The gateway will start proxying the services at `http://localhost:8080`.

### Kubernetes deployment

For the Kubernetes deployment first of all the gateway must be compiled into a docker image and uploaded into a registry accessible by the Kubernetes cluster:

```bash
git clone <repo>
cd gateway
docker build . -t <docker-registry>/gateway:latest
docker push <docker-registry>/gateway-latest
```

The name of the image is specified in the gateway deployment file, [gateway_deployment.yaml](YAMLs/gateway_deployment.yaml). In that file you can also specify a registry secret in case the registry is behind authorization. Here is the documentation regarding [private registries](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/).

The deployment file contains several environment variables which can be modified:

| Environment Variable | description                                              | default                                 |
|----------------------|----------------------------------------------------------|-----------------------------------------|
| LOG_LEVEL            | Logs verbose levels                                      | debug                                   |
| GH_REALM             | Keycloak realm used for authentication and authorization | GravitateHealth                         |
| AUTH_SERVER          | URL of the authentication and authorization server       | https://gravitate-health.lst.tfo.upm.es |
| SSL_REQ              | SSL required for the authorization redirects             | external                                |
| CLIENT_ID            | ID of the Keycloak client                                | GravitateHealth                         |
| PUBLIC_CLIENT        | If the Keycloak client is public                         | true                                    |
| CONFIDENTIAL_PORT    | In case the Keycloak is confidential, which port         | 0                                       |

The next step is to apply the Kubernetes files in the cluster, the services will be deployed in the development namespace. In case the namespace has not been created before you can create it with the following commands, or change the name in metadata.namespace:

```bash
kubectl create namespace <namespace>                         # Only if namespace not created and/or the current context
kubectl config set-context --current --namespace=<namespace> # Only if namespace not created and/or the current context

kubectl apply -f YAMLs/gateway_deployment.yaml
kubectl apply -f YAMLs/gateway_service.yaml
```

You can check if the deployment is ready by running:

```bash
kubectl get pod | grep "gateway"
```
```bash
NAMESPACE            NAME                                         READY   STATUS    RESTARTS        AGE
<namespace>          gateway-6db6b64d5f-tqljd                     1/1     Running   0               10s
```

If the pod is ready you can access the service by other services in the same namespace by using the name of its Kubernetes service and the port (especified in [gateway_service.yaml](YAMLs/gateway_service.yaml)). You can also obtain both by running the following commands:

```bash
kubectl get svc | grep "gateway"
```
```bash
NAME      TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
gateway   NodePort   10.108.141.168   <none>        8080:32036/TCP   28s
```

In the case of this service the service type is NodePort, which will make th service available directly in the machine running the cluster at ```http://<machine-ip>:<nodePort>```. This should only be used for testing, for production environments the type should be changed to ClusterIP, which will only expose the service internally to the cluster. Moreover, if the Kubernetes cluster has a DNS manager other services can access services in other namespaces using the following URL: ```http://<service-name>.<namespace>.svc.cluster.local```. To learn more about the types of services and its uses in Kubernetes, here is the [official documentation](https://kubernetes.io/docs/concepts/services-networking/).

#### Expose the gateway to the outside of the cluster

Usage
-----

### Basic operation


### Additional options


Known issues and limitations
----------------------------


Getting help
------------


Contributing
------------


License
-------

This project is distributed under the terms of the [Apache License, Version 2.0 (AL2)](http://www.apache.org/licenses/LICENSE-2.0).  The license applies to this file and other files in the [GitHub repository](https://github.com/Gravitate-Health/Gateway) hosting this file.

```
Copyright 2022 Universidad Politécnica de Madrid

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

Authors and history
---------------------------


Acknowledgments
---------------
