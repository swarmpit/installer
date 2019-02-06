# Swarmpit installer

Swarmpit platform installer

## Run

```{r, engine='bash', count_lines}
docker run -it \ 
  --rm \
  --name swarmpit-installer \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  swarmpit/install:1.5
```
