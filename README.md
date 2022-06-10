
Gravitate Health Gateway: Express Gateway
=================================================

[![Latest release](https://img.shields.io/github/v/release/mhucka/readmine.svg&color=b44e88)](https://github.com/mhucka/readmine/releases)
[![Python](https://img.shields.io/badge/python-v3.6+-blue.svg)]()
[![Build Status](https://travis-ci.org/anfederico/clairvoyant.svg?branch=master)](https://travis-ci.org/anfederico/clairvoyant)
[![Tests](https://img.shields.io/jenkins/tests?compact_message)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

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

This section explains the principles behind this README file.  If this repository were for actual _software_, this [Usage](#usage) section would explain more about how to run the software, what kind of output or behavior to expect, and so on.

### Basic operation

A suggested approach for using this example README file is as follows:

1. Copy the [source file](README.md) for this file to your repository and commit it to your version control system
2. Delete all the body text but keep the section headings
3. Write your README content
4. Commit the new text to your version control system
5. Update your README file as your software evolves

The first paragraph in the README file (under the title at the very top) should summarize your software in a concise fashion, preferably using no more than one or two sentences.

<p align="center"><img width="80%" src=".graphics/screenshot-top-paragraph.png"></p>

The space under the first paragraph and _before_ the [Table of Contents](#table-of-contents) is a good location for optional [badges](https://github.com/badges/shields), which are small visual tokens commonly used on GitHub repositories to communicate project status, dependencies, versions, DOIs, and other information.  The particular badges and colors you use depend on your project and personal tastes.

The [Introduction](#introduction) and [Usage](#usage) sections are described above.

In the [Known issues and limitations](#known-issues) section, summarize any notable issues and/or limitations of your software.  The [Getting help](#getting-help) section should inform readers of how they can contact you, or at least, how they can report problems they may encounter.  The [Contributing](#contributing) section is optional; if your repository is for a project that accepts open-source contributions, then this section is where you can explain to readers how they can go about making contributions.

The [License](#license) section should state any copyright asserted on the project materials as well as the terms of use of the software, files and other materials found in the project repository.  Finally, the [Authors and history](#authors-and-history) section should inform readers who the authors are; it is also a place where you can acknowledge other contributions to the work and the use of other people's software or tools.

### Additional options

Some projects need to communicate additional information to users and can benefit from additional sections in the README file.  It's difficult to give specific instructions &ndash; a lot depends on your software, your intended audience, etc.  Use your judgment and ask for feedback from users or colleagues to help figure out what else is worth explaining.


Known issues and limitations
----------------------------

In this section, summarize any notable issues and/or limitations of your software.  If none are known yet, this section can be omitted (and don't forget to remove the corresponding entry in the [Table of Contents](#table-of-contents) too); alternatively, you can leave this section in and write something along the lines of "none are known at this time".


Getting help
------------

Inform readers of how they can contact you, or at least how they can report problems they may encounter.  This may simply be a request to use the issue tracker on your repository, but many projects have associated chat or mailing lists, and this section is a good place to mention those.


Contributing
------------

Mention how people can offer contributions, and point them to your guidelines for contributing.


License
-------

This README file is distributed under the terms of the [Creative Commons 1.0 Universal license (CC0)](https://creativecommons.org/publicdomain/zero/1.0/).  The license applies to this file and other files in the [GitHub repository](http://github.com/mhucka/readmine) hosting this file. This does _not_ mean that you, as a user of this README file in your software project, must also use CC0 license!  You may use any license for your work that you see fit.


Authors and history
---------------------------

In this section, list the authors and contributors to your software project.  (The original author of this file is [Mike Hucka](http://www.cds.caltech.edu/~mhucka/).)  Adding additional notes here about the history of the project can make it more interesting and compelling.


Acknowledgments
---------------

If your work was funded by any organization or institution, acknowledge their support here.  In addition, if your work relies on other software libraries, or was inspired by looking at other work, it is appropriate to acknowledge this intellectual debt too.  For example, in the process of developing this file, I used not only my own ideas and experiences &ndash; I read many (sometimes contradictory) recommendations for README files and examined real READMEs in actual use, and tried to distill the best ideas into the result you see here.  Sources included the following:

* http://tom.preston-werner.com/2010/08/23/readme-driven-development.html
* https://changelog.com/posts/top-ten-reasons-why-i-wont-use-your-open-source-project
* https://thoughtbot.com/blog/how-to-write-a-great-readme
* http://jonathanpeelle.net/making-a-readme-file
* https://github.com/noffle/art-of-readme
* https://github.com/noffle/common-readme
* https://github.com/RichardLitt/standard-readme
* https://github.com/jehna/readme-best-practices
* https://gist.github.com/PurpleBooth/109311bb0361f32d87a2
* https://github.com/matiassingers/awesome-readme
* https://github.com/cfpb/open-source-project-template
* https://github.com/davidbgk/open-source-template/
* https://www.makeareadme.com
* https://github.com/lappleapple/feedmereadmes
* https://github.com/badges/shields