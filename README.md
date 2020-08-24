# Druid on Kubernetes

- [Get Started with Minikube](#get-started-with-minikube)
  * [Test drive the cluster](#test-drive-the-cluster)
- [Get Serious with GKE](#get-serious-with-gke)
  * [Build and prepare](#build-and-prepare)
  * [Deploy](#deploy)
  * [Common issues](#common-issues)

## Get Started with Minikube

To get started with Minikube, a fairly large VM is required; run:
```bash
minikube start -p druid --kubernetes-version=1.18.0 --cpus=8 --memory=24GiB

source <(minikube docker-env -p druid)
```

Now fire up the Makefile with:
```
# this assumes `kubectl`'s active context is minikube's in addition to the above being run
make minikube
```

So in 3 commands we:
- started our minikube VM
- sourced its docker config into our environment
- built the druid exporter image (by way of make dependency)
- deployed the minikube Druid configuration

The minikube Druid configuration is a full-blown cluster despite being on a single machine; so if looking for information in the docs, focus on [cluster](https://druid.apache.org/docs/latest/tutorials/cluster.html) not [single-server](https://druid.apache.org/docs/latest/operations/single-server.html) configurations.

In about 2-many minutes (the druid image can take a long time to download and untar) the zookeeper instances will come alive and the druid components will all start.
You can check this out with:
```bash
kubectl get pod -n druid
# as well as the battery of other kubectl tools at one's disposal: `get event`, `logs`, `describe`, etc.
```

Once the `router` Statefulset is up, you can find the `ip:port` of the router LB with:
```bash
minikube service list -p druid | grep router-lb
```
And plug it into your browser.
Presto!
You're ready to start hacking away with a full-blown Druid cluster.

### Test drive the cluster

Check out their [getting started](https://github.com/apache/druid/#getting-started) section to see some quick hits and their [tutorials](https://druid.apache.org/docs/latest/tutorials/tutorial-batch.html) for more in depth information.
The easiest and my personal favorite to sanity check the cluster health is to do the following:
- With the browser page on the Druid console
- Click `Load Data` along the top header of the page
- Click `Example data` (lightbulb icon)
- Select `Wikipedia Edits` if not already selected from the dropdown on the right hand side
- Click `Load example` beneath same dropdown
- Follow the prompts, selecting all the defaults; the `Next` buttons are in the bottom right of the page
- Finally, click `Submit`

You should get dropped onto the `Ingestion` page where you can track the status of the task.
Afterwards when it shows `SUCCESS` status, you can find the indexed data under `Datasources` and `Segments` pages.
And last but not least, `Query`!
The query tab should be entirely functional and ready to rock with whatever power your PC and VM will bear.

Happy Druid-ing(?)!

## Get Serious with GKE

*This was sadly tested some time ago on an older version of druid, and while the manifests and kustomizations should be in line with minikube, some breakage may be encountered.*

So you wanna do this for real, huh?
Who wouldn't?!
Running this on a cloud platform makes it infinitely (theoretically, certainly) scalable: all the data and logs are stored in an object store, leaving cpu and memory as the only components we need to truly plan for.
And with features like [horizontal pod autoscaling](https://cloud.google.com/kubernetes-engine/docs/concepts/horizontalpodautoscaler) and [cluster autoscaling](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler), the system need not waste your money when you aren't flexing it hard.
And beyond that, Druid handles the rest and has robust configurations for many use cases even in its incubtating state.

Well, you asked for it; +prepare for the worst because+...nah it's pretty easy.
But that said there are definitely some requirements up front (and one recommendation):
1. [Config Connector](https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall) is deployed in the cluster and has the appropriate permissions to manage Cloud SQL Instances and GCS Buckets
  - (unless Config Connector has evolved since I last encountered this, I _strongly_ recommend using a curated IAM Role and not simply giving the Config Connector blanket admin access to the project; however, your situation may allow for such configurations)
1. [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) is enabled and there's a [binding](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#creating_a_relationship_between_ksas_and_gsas) for the IAM Service Account and the K8s Service Account
1. A private network serice access range is configured; information about postgres' needs can be found [here](https://cloud.google.com/sql/docs/postgres/private-ip). This is however, only required because the `SqlInstance` is configured as such and can be changed easily; see [the doc](https://cloud.google.com/config-connector/docs/reference/resource-docs/sql/sqlinstance)

How these are deployed is entirely up to you, but they are required for the given kustomization in this repo.
To untangle any of that, one simply needs to (either or both if Config Connector or Workload Identity aren't in use):
- Create the Postgres instance manually (there's a wonderful [helm chart](https://hub.helm.sh/charts/bitnami/postgresql) for this) or via API and remove the `SqlInstance` and other config connector resource references from the gke kustomization
- Create the GCS Bucket manually or via API and similarly remove the associated config connector resources from the gke kustomization (`StorageBucket`)
- Use a generated GCP Service Account JSON key and a K8s secret with env var wiring for `GOOGLE_APPLICATION_CREDENTIALS` in all the workloads that talk to the indexing and logging backends (kind of all of them except maybe the router?)

Recommendation:
- The GKE cluster this was deployed to and tested against is a [Private Cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept) which means nearly-zero wire connectivity to and from the outside world. I'm a personal advocate of private clusters, but it's not strictly required here. However, to get access to the deployed instances and LBs (they should all be Internal L4 LBs), you will need to find your way onto a network with visibility to either the Service IP alias range (a VPC peered with the GKE VPC) or the k8s master (the GKE VPC itself). You can do this with VPNs, tools like [sshuttle](https://github.com/sshuttle/sshuttle) and jump servers, or even [Cloud Shell](https://cloud.google.com/shell) if you really like/trust/enjoy that experience.

And with that out of the way we're ready to get started!

### Build and prepare

Building isn't required as [quay.io](https://quay.io/repository/dmarkwat/wikimedia-druid-exporter?tab=tags) is nice enough to offer to build the exporter at no charge.
You can use the repo, `quay.io/dmarkwat/wikimedia-druid-exporter`, and whichever tag or digest you prefer.
(Bear in mind, this isn't a versioned repo--digests are therefore recommended).

But in the event you want to build and host this yourself:
```bash
# update with whatever docker repo of your choosing
TAG=gcr.io/your-project-here/druid-exporter:latest

# must specify the tag for any push to be meaningful
make build TAG=$TAG

# up, up, and away with the image
docker push $TAG
```

Then, find all the things that need changing:
```bash
grep -R 'change-me' kustomize/gke
```
This is a super low tech way to find everything that needs to change, but `kustomize` has somewhat limited variable plugging (when last I used it anyway).
Among the `change-me`s you'll find are things like:
- postgres IP addresses
- passwords that suuuuper should be changed
- workload identity project name
- GCS bucket names
- druid exporter name and digest

There should hopefully be enough context or comments inline to aid with the values these should be set to.
And bear in mind this is only a few of the required elements; things like JVM tuning, etc. can be found in various `jvm.config` or other files and will be required for expert or production-grade tuning.

Lastly, don't forget the IAM bindings.
While the `SqlInstance` and `StorageBucket`s are all in here, the IAM configurations are not!
So don't forget to update IAM accordingly for the workload-identity-bound GCP SA.
Yes, there is definitely some chicken-egg silliness going on here and so you will likely need to apply these configurations _and then_ apply the IAM bindings.
But, you can also add the necessary IAM bindings using Config Connector CRs...however, I personally have avoided allowing Config Connector to manage IAM policies; but you decide!

### Deploy

Once that's all set, we simply run:
```bash
# this assumes there's wire access to the k8s master--sshuttle, vpn, etc.
# and also that the kube context is configured for the correct cluster

make gke
```

Within about 5-several minutes everything should come online.
Cloud SQL is likely to be the slowest part of this process and since many components depend on it, it's possible you will see crash-looping until it comes online.

If there are no issues then you're ready to [test drive the cluster](#test-drive-the-cluster)!

Happy Druid-ing(?)!

### Common issues

I could spend hours documenting these, but sadly I won't here; so to just to give some quick hits:
- Cloud SQL IP ACLs and network connectivity between the private service access range and the GKE VPC are misconfigured
- Workload identity is misconfigured; however, containers making use of workload identity often fail on the first one or few starts because the gke metadata server backing WI is--as far as I understand it and have observed--an eventually consistent system. So don't let the first auth-related failure fool you!
- IAM on the GCP service account is misconfigured; it needs access to whatever buckets you create
