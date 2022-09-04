# Swarmpit installer

Swarmpit platform installer

For **1.9** release and older please refer to following [guide](https://github.com/swarmpit/installer/tree/8b947373547e977dab86760773f55bd1e3d1d4f5)

## Run 

### Interactive mode
User is prompted to setup application from command line.

Example:

```{r, engine='bash', count_lines}
docker run -it --rm \
  --name swarmpit-installer \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  swarmpit/install:edge
```

### Non-interactive mode
Setup is done based on environment variables passed to installer. 
Interactive mode must be set to 0 (disabled).

Example:

```{r, engine='bash', count_lines}
docker run -it --rm \
  --name swarmpit-installer \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  -e INTERACTIVE=0 \
  -e STACK_NAME=swarmpit \
  -e APP_PORT=888 \
  swarmpit/install:edge
```

#### Parameters

##### Mandatory 

- INTERACTIVE - must be set to **0** (disabled)

##### Optional 

- STACK_NAME - default to **swarmpit**
- APP_PORT - default to **888**
- DB_VOLUME_DRIVER - default to **local**
