# Library Search Workflow

Getting the data to run

```
cd data
sh ./get_data.sh
```

To run the workflow to test simply do

```
make run
```

We recommend nextflow 24.10 to run. 


## Installation

You will need to have conda, mamba, and nextflow installed. 

## Using the Code
This code uses other modules such as the `NextflowModules`. Make sure to run the following after cloning the code:
```
git submodule update --init --recursive
```

## Deployment to GNPS2

In order to deploy, we have a set of deployment tools that will enable deployment to the various gnps systems. To run the deployment, use the following commands from the deploy_gnps2 folder. 

```
make deploy-prod
```

You might need to checkout the module, do this by running

```
git submodule init
git submodule update
```
