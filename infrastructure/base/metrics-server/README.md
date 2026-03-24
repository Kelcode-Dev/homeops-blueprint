# Metrics Server

## Talos Prerequisites

Talos needs to be slightly reconfigured to allow for the rotation of node certificates e.g.

```yaml
machine:
  kubelet:
    extraArgs:
      rotate-server-certificates: true
```

See https://docs.siderolabs.com/kubernetes-guides/monitoring-and-observability/deploy-metrics-server for more details

Patching the nodes directly can be easily done via the talosctl cli tool using:

```bash
for ip in 192.168.0.{121..123} 192.168.0.{131..136}; do
  echo "Patching $ip..."
  talosctl patch mc -p '{"machine": {"kubelet": {"extraArgs": {"rotate-server-certificates": "true"}}}}' -n $ip
done
```

Give it a couple of minutes then run `kubectl get csr -n metrics-server` and you should see a whole new set of certificates being generated, one for each node in your cluster

```bash
$ kubectl get csr
NAME        AGE     SIGNERNAME                      REQUESTOR                   REQUESTEDDURATION   CONDITION
csr-449hp   4m32s   kubernetes.io/kubelet-serving   system:node:talos-dkl-v8o   <none>              Approved,Issued
csr-b5wdp   4m54s   kubernetes.io/kubelet-serving   system:node:talos-md6-8mh   <none>              Approved,Issued
csr-bh5kl   4m32s   kubernetes.io/kubelet-serving   system:node:talos-0bb-00v   <none>              Approved,Issued
csr-hsh72   4m33s   kubernetes.io/kubelet-serving   system:node:talos-w1t-vop   <none>              Approved,Issued
csr-l58c9   4m33s   kubernetes.io/kubelet-serving   system:node:talos-wzp-3qq   <none>              Approved,Issued
csr-nhws2   4m32s   kubernetes.io/kubelet-serving   system:node:talos-tac-5ol   <none>              Approved,Issued
csr-r82cc   4m32s   kubernetes.io/kubelet-serving   system:node:talos-qjo-r1d   <none>              Approved,Issued
csr-tk2rv   4m32s   kubernetes.io/kubelet-serving   system:node:talos-cft-wry   <none>              Approved,Issued
csr-xr65f   4m32s   kubernetes.io/kubelet-serving   system:node:talos-hpf-mmd   <none>              Approved,Issued
```
