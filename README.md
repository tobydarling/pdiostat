# pdiostat
Run iostat on the servers of a clustered filesystem using pdsh

## Prerequisites
pdsh setup up with ssh keys for all servers that are
part of your clustered filesystem. If your hosts are in
group ''beegfs'', the following should return their hostnames:

```
pdsh -g beegfs hostname
```


