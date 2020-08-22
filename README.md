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
