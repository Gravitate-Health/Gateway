
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
    - [Example operation](#example-operation)
    - [Runtime addition of new APIs](#runtime-addition-of-new-apis)
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
git clone https://github.com/Gravitate-Health/Gateway.git
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
git clone https://github.com/Gravitate-Health/Gateway.git
cd gateway
docker build . -t <docker-registry>/gateway:latest
docker push <docker-registry>/gateway:latest
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

The next step is to apply the Kubernetes files in the cluster, the services will be deployed in the development namespace. In case the namespace has not been created before you can create it with the following commands, or change the name in `metadata.namespace`:

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

In the case of this service the service type is NodePort, which will make the service available directly in the machine running the cluster at ```http://<machine-ip>:<nodePort>```. This should only be used for testing, for production environments the type should be changed to ClusterIP, which will only expose the service internally to the cluster. Moreover, if the Kubernetes cluster has a DNS manager other services can access services in other namespaces using the following URL: ```http://<service-name>.<namespace>.svc.cluster.local```. To learn more about the types of services and its uses in Kubernetes, here is the [official documentation](https://kubernetes.io/docs/concepts/services-networking/).

#### Expose the gateway to the outside of the cluster

In order to expose the gateway to the outside of the cluster an [Ingress Kubernetes](https://kubernetes.io/docs/concepts/services-networking/ingress/) resource is needed. In this repository there are examples of both [non-TLS](YAMLs/ingress.yaml) and [TLS](YAMLs/ingress-tls.yaml). As the gateway does not terminate TLS it is recommended to deploy and Ingress with TLS enabled, in our case we used Lets encrypt to generate the certificates.

To install the Ingress the process is the same as the deployment and service:

```bash
kubectl apply -f YAMLs/ingress-tls.yaml
```

If there are no errors the entry point to the platform will be available at your DNS name.

Usage
-----

The usage of the Gateway is limited to the usage of the services it proxies. You can also use the admin API to add new services at runtime, if open. It functions as a reverse proxy, terminating TLS for the services inside the cluster. In the table below you can find a list of services and the API endpoints to access them.

|     Service                                     |     API Endpoint                   |
|-------------------------------------------------|------------------------------------|
|     FHIR Server                                 |     /fhir                          |
|     FHIR Connector                              |     /fhir-connector                |
|     G-Lens Medication Information               |     /med-information               |
|     G-Lens Medication Management                |     /med-management                |
|     G-Lens Health and Wellbeing file storage    |     /health-wellbeing              |
|     G-Lens Health and Wellbeing   interface     |     /health-wellbeing-interface    |
|     Prometheus                                  |     /prometheus                    |
|     Grafana                                     |     /grafana                       |
|     Keycloak                                    |     /realms                        |

### Example operation

In the following example we will use the Gateway to send a request to the FHIR server, protected behind authentication:

First, we need to obtain the authorization token from Keycloak. For that, we need to send a POST request with the login info to the token provider of Keycloak, which in our case is accesible behind the Gateway.

The parameters are the following:
- client_id: GravitateHealth
- grant_type: password
- username: \<username>
- password: \<password>

A request example:

```bash
curl --location --request POST 'https://<url>/realms/GravitateHealth/protocol/openid-connect/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=GravitateHealth' \
--data-urlencode 'grant_type=password' \
--data-urlencode 'username=myuser' \
--data-urlencode 'password=mypassword'
```

The response should look like this:

```JSON
{
    "access_token": "<TOKEN>",
    "expires_in": 300,
    "refresh_expires_in": 1800,
    "refresh_token": "<REFRESH_TOKEN>",
    "token_type": "Bearer",
    "not-before-policy": 0,
    "session_state": "48b9d271-2858-47bc-b6b8-a36e5afe9d0c",
    "scope": "email profile"
}
```

- **access_token**: Using this token in the authorization header will grant access to the rest of the services. 
- **expires_in**: Time in seconds for the access token to expire
- **refresh_expires_in**: Time in seconds for the refresh token to expire
- **refresh_token**: Can be used to request a new access token without the need of inputting the user credentials again. The request is to the same URL as the token, but with the following parameters:
refresh_token: <refresh_token>
  - grant_type: refresh_token
  - client_id: GravitateHealth
  - token_type: The type of the token, in our case “Bearer”
- **not-before-policy**: This policy ensures that any tokens issued before that time become invalid, in our case 0
- **session_state**: ID of the session
- **scope**: Scopes of the user, basically the roles permissions

Once we have the token we can now query the FHIR server for its metadata component, for example.

```bash
curl --location --request GET 'https://<url>/fhir/metadata' \
--header 'Authorization: Bearer <TOKEN>'
```

### Runtime addition of new APIs

In order to add a new API to the Gateway 3 objects have to be created, a service endpoint, a pipeline and an API endpoint. The following is an example of the FHIR server.

- Service endpoint: The url to proxy
```JSON
{
  "url":"http://fhir-server:8080"
}
```
- Pipeline: The policies flow, for example, first rewrite, then auth, then proxy.
```JSON
{
  "apiEndpoints":["fhir-server"],
  "policies":[{
    "cors": "",
    "keycloak-protect": "",
    "proxy":[{
      "action":{
        "changeOrigin": false,
        "xfwd": true,
        "serviceEndpoint": "fhir-server"
        }
    }]
  }]
}
```
- API endpoint: The API endpoints to proxy.
```JSON
{
  "host":"*",
  "paths":["/fhir/*"]
}
```

The documentation for this operation can be found in the [official documentation](https://www.express-gateway.io/docs/admin/) of Express Gateway.

Known issues and limitations
----------------------------

There is no persistence to the APIs added at runtime, meaning that if the pod were to restart those changes will be lost. It also shouldn't be used with more than one replica if planning to add APIs at runtime, as the load balancer might redirect the requests to different pods.

Getting help
------------

In case you find a problem or you need extra help, please use the issues tab to report the issue.

Contributing
------------

To contribute, fork this repository and send a pull request with the changes squashed.

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

- Álvaro Belmar ([@abelmarm](https://github.com/abelmarm))

Acknowledgments
---------------

- https://www.keycloak.org/docs/latest/securing_apps/
- https://www.express-gateway.io/docs/
- https://kubernetes.io/docs/home/
