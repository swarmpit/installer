# Swarmpit installer

Swarmpit platform installer

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
  -e ADMIN_USERNAME=randy \
  -e ADMIN_PASSWORD=test1234 \
  swarmpit/install:edge
```

#### Parameters

##### Mandatory 

- INTERACTIVE - must be set to **0** (disabled)
- ADMIN_PASSWORD - must be at least 8 characters long

##### Optional 

- STACK_NAME - default to **swarmpit**
- ADMIN_USERNAME - default to **admin**
- APP_PORT - default to **888**
- DB_VOLUME_DRIVER - default to **local**
