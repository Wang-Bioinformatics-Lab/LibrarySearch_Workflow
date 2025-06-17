run:
	nextflow run ./nf_workflow.nf -resume -c nextflow.config

run_forceoffline:
	nextflow run ./nf_workflow.nf -resume -c nextflow.config --forceoffline=Yes --searchtool=gnps

run_forceoffline_analog:
	nextflow run ./nf_workflow.nf -resume -c nextflow.config --forceoffline=Yes --searchtool=gnps_indexed --analog_search=1

init_modules:
	git submodule update --init --recursive