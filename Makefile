run:
	nextflow run ./nf_workflow.nf -resume -c nextflow.config

run_forceoffline:
	nextflow run ./nf_workflow.nf -resume -c nextflow.config --forceoffline=Yes --searchtool=gnps_indexed
