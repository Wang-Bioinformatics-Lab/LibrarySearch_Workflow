#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.inputlibraries = "data/libraries"
params.inputspectra = "data/spectra"

// Parameters
params.searchtool = "gnps" // blink, gnps, gnps_new, gnps_indexed

params.topk = 1

params.fragment_tolerance = 0.5
params.pm_tolerance = 2.0

params.library_min_similarity = 0.7
params.library_min_matched_peaks = 6

params.merge_batch_size = 1000 //Not a UI parameter

// Parameters for Interacting with GNPS Libraries
params.forceoffline = "No" // Yes or No

// Filtering structures
params.filtertostructures = "0" // 1 means we filter to only hits with structures

//TODO: Implement This
params.filter_precursor = 1
params.filter_window = 1

//TODO: Implement This
params.analog_search = "0"
params.analog_max_shift = 1999

// GNPS_New Parameters
params.search_algorithm = "cos"
params.peak_transformation = 'sqrt'
params.unmatched_penalty_factor = 0.6

// Blink Parameters
params.blink_ionization = "positive"
params.blink_minpredict = 0.01

params.publishdir = "$launchDir"
TOOL_FOLDER = "$moduleDir/bin"
MODULES_FOLDER = "$TOOL_FOLDER/NextflowModules"


// COMPATIBILITY NOTE: The following might be necessary if this workflow is being deployed in a slightly different environemnt
// checking if outdir is defined,
// if so, then set publishdir to outdir
if (params.outdir) {
    _publishdir = params.outdir
}
else{
    _publishdir = params.publishdir
}

// Augmenting with nf_output
_publishdir = "${_publishdir}/nf_output"

include {summaryLibrary; searchDataGNPS; searchDataGNPSNew; searchDataGNPSIndexed; searchDataBlink; 
 mergeResults; librarygetGNPSAnnotations; filtertop1Annotations;
  formatBlinkResults; chunkResults} from "$MODULES_FOLDER/nf_library_search_modules.nf" addParams(publishdir: _publishdir)

workflow Main{
    take:
    input_map
    /*
        The input map should contain the following parameters:
        [inputlibraries
        inputspectra
        searchtool
        topk
        fragment_tolerance
        pm_tolerance
        library_min_cosine
        library_min_matched_peaks
        merge_batch_size
        filtertostructures
        filter_precursor
        filter_window
        analog_search
        analog_max_shift
        blink_ionization
        blink_minpredict]
        */

    main:
    libraries_ch = Channel.fromPath(input_map.inputlibraries + "/*.mgf" )
    spectra = Channel.fromPath(input_map.inputspectra + "/**", relative: true)

    // Lets create a summary for the library files
    library_summary_ch = summaryLibrary(libraries_ch)

    // Merging all these tsv files from library_summary_ch within nextflow
    library_summary_merged_ch = library_summary_ch.collectFile(name: "${input_map.publishdir}/library_summary.tsv", keepHeader: true)
    
    if(input_map.searchtool == "gnps" || input_map.searchtool == "gnps_indexed"){
        // Perform cartesian product producing all combinations of library, spectra
        inputs = libraries_ch.combine(spectra)

        // For each path, add the path as a string for file naming. Result is [library_file, spectrum_file, spectrum_path_as_str]
        // Must add the prepend manually since relative does not include the glob.
        inputs = inputs.map { it -> [it[0], file(input_map.inputspectra + '/' + it[1]), it[1].toString().replaceAll("/","_"), it[1]] }

        if (input_map.searchtool == "gnps_indexed") {
            // If the search tool is gnps_indexed, we need to use the indexed search
            search_results = searchDataGNPSIndexed(inputs, input_map.pm_tolerance, input_map.fragment_tolerance,
             input_map.topk, input_map.library_min_similarity, input_map.library_min_matched_peaks,
              input_map.analog_search, input_map.filter_precursor, input_map.filter_window)
        }
        else {
            // Otherwise, we use the regular GNPS search
            search_results = searchDataGNPS(inputs, input_map.pm_tolerance, input_map.fragment_tolerance,
             input_map.topk, input_map.library_min_similarity, input_map.library_min_matched_peaks,
              input_map.analog_search, input_map.filter_precursor, input_map.filter_window)
        }

        chunked_results = chunkResults(search_results.buffer(size: input_map.merge_batch_size, remainder: true), input_map.topk)
       
        // Collect all the batched results and merge them at the end
        merged_results = mergeResults(chunked_results.collect(), input_map.topk)
    }
    else if (input_map.searchtool == "blink"){
        // Must add the prepend manually since relative does not inlcude the glob.
        spectra = spectra.map { it -> file(input_map.inputspectra + '/' + it) }
        search_results = searchDataBlink(libraries_ch, spectra, input_map.blink_ionization, input_map.blink_minpredict, input_map.fragment_tolerance)

        formatted_results = formatBlinkResults(search_results)

        merged_results = mergeResults(formatted_results.collect(), input_map.topk)
    }
    else if (input_map.searchtool == "gnps_new"){
        spectra_abs = Channel.fromPath(input_map.inputspectra + "/**", relative: false)

        // Perform cartesian product producing all combinations of library, spectra
        inputs = libraries_ch.combine(spectra_abs)

        search_results = searchDataGNPSNew(inputs, input_map.search_algorithm, input_map.analog_search, input_map.analog_max_shift, input_map.pm_tolerance, input_map.fragment_tolerance, input_map.library_min_similarity, input_map.library_min_matched_peaks, input_map.peak_transformation, input_map.unmatched_penalty_factor)

        merged_results = mergeResults(search_results.collect(), input_map.topk)
    }

    annotation_results_ch = librarygetGNPSAnnotations(merged_results, library_summary_merged_ch,
     input_map.topk, input_map.filtertostructures, input_map.forceoffline)

    // Getting another output that is only the top 1
    filtertop1Annotations(annotation_results_ch)

    emit:
    annotation_results_ch
}

workflow {
    input_map = [
        inputlibraries: params.inputlibraries,
        inputspectra: params.inputspectra,
        searchtool: params.searchtool,
        topk: params.topk,
        fragment_tolerance: params.fragment_tolerance,
        pm_tolerance: params.pm_tolerance,
        library_min_similarity: params.library_min_similarity,
        library_min_matched_peaks: params.library_min_matched_peaks,
        merge_batch_size: params.merge_batch_size,
        forceoffline: params.forceoffline,
        filtertostructures: params.filtertostructures,
        filter_precursor: params.filter_precursor,
        filter_window: params.filter_window,
        analog_search: params.analog_search,
        analog_max_shift: params.analog_max_shift,
        blink_ionization: params.blink_ionization,
        blink_minpredict: params.blink_minpredict,
        publishdir: params.publishdir,
        search_algorithm: params.search_algorithm,
        peak_transformation: params.peak_transformation,
        unmatched_penalty_factor: params.unmatched_penalty_factor,
        filter_precursor: params.filter_precursor,
        filter_window: params.filter_window
    ]
    
    Main(input_map)
}