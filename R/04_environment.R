#' Initialize diyabcGUI package global environment
#' @keywords internal
#' @author Ghislain Durif
#' @description
#' Initialize container for each type of project 
#' (diyabc-rf analysis and data generation) inside `diyabcGUI` global 
#' environment.
init_diyabc_env <- function() {
    # diyabc-rf analysis project
    assign("ap", reactiveValues(), env)
    
    # diyabc-rf dataset metadata
    assign("md", reactiveValues(), env)
    
    # diyabc-rf training set simulation sub-module
    assign("ts", reactiveValues(), env)
    
    # diyabc-rf random forest sub-module
    assign("rf", reactiveValues(), env)
    
    # data generation project
    assign("dp", reactiveValues(), env)
}

#' Initialize environment for DIYABC-RF pipeline
#' @keywords internal
#' @author Ghislain Durif
init_diyabcrf_env <- function() {
    ## environment attributes
    
    # analysis project
    tmp_ap <- list(
        ## project setup
        proj_name = NULL,       # project name
        proj_dir = NULL,        # project directory
        locus_type = "snp",     # "snp" or "mss"
        seq_mode = "indseq",    # "indseq" or "poolseq"
        proj_type = "new",      # "new", "existing" or "example"
        proj_file_list = NULL,  # content of the project
        file_modif = NULL,      # counter for project file modification 
                                # (upload, new header, ...)
        file_upload = NULL,     # counter for project file upload
        header_check = NULL,    # result of header file check
        reftable_check = NULL,  # result of reftable file check
        statobs_check = NULL,   # result of statobs file check
        ## observed data
        data_file = NULL,       # observed data file name
        data_check = NULL       # result of data file check
    )
    
    # dataset metadata
    tmp_md <- list(
        # number of loci in the data file
        n_loci = NULL,
        # table of locus description: name, type, number
        locus_des = NULL
    )
    
    # training set simulation
    tmp_ts <-list(
        # new project
        new = FALSE,
        # existing project
        existing = FALSE,
        # edit project
        edit = FALSE,
        # list of historical models
        scenario_list = NULL,
        # total number of parameters in all model
        n_param = NULL,
        # list of number of parameters per model
        n_param_list = NULL,
        # list of model priors (discrete probabilities)
        model_prior = NULL,
        # list of historical model parameters (name, type, priors)
        prior_list = NULL,
        # list of conditions on historical parameters
        cond_list = NULL,
        # table of loci description
        locus_desc = NULL,
        # number of loci group
        n_group = NULL,
        # list of group priors for MSS data
        group_prior_list = NULL,
        # specific ref table column names for MSS data
        mss_reftab_colname = NULL
    )
        
    # random forest analysis
    tmp_rf <- list(
        # analysis (sub-project) name
        proj_name = NULL,
        # analysis mode: "param_estim" or "model_choice"
        mode = NULL,
        # number of samples to use
        n_rec = NULL,
        # minimal node size
        min_node_size = NULL, 
        # number of tree
        n_tree = NULL, 
        # number of noise columns
        n_noise_columns = NULL, 
        # boolean: if TRUE, enable LDA for model choice or PLS for 
        #   parameter estimation
        linear = NULL, 
        # percentage of maximum explained Y-variance for retaining pls axis
        pls_max_var = NULL, 
        # Chosen scenario (mandatory for parameter estimation)
        chosen_scenario = NULL, 
        # number of oob testing samples (mandatory for parameter estimation)
        noob = NULL, 
        # name of the parameter of interest (mandatory for parameter 
        #   estimation)
        parameter = NULL, 
        # subset and/or groups of models
        grouping = NULL,
        # abcranger run counter
        run_counter = NULL
    )
    
    
    ## clean up and define environment
    list2reactiveValues(tmp_ap, ap)
    list2reactiveValues(tmp_md, md)
    list2reactiveValues(tmp_ts, ts)
    list2reactiveValues(tmp_rf, rf)
}

#' Project env reset
#' @keywords internal
#' @author Ghislain Durif
reset_ap <- function() {
    env$ap$header_check <- NULL
    env$ap$reftable_check <- NULL
    env$ap$statobs_check <- NULL
    env$ap$data_file <- NULL
    env$ap$data_check <- NULL
}

#' Reset environment for DIYABC-RF pipeline
#' @keywords internal
#' @author Ghislain Durif
reset_diyabcrf_env <- function() {
    # proj dir
    env$ap$proj_dir <- mk_proj_dir("diyabc_rf")
    # ap reset
    reset_ap()
    # reset specific var
    env$ap$locus_type <- "snp"
    env$ap$seq_mode <- "indseq"
    env$ap$proj_type <- "new"
    # proj files
    update_proj_file("ap")
    upload_proj_file("ap")
}

#' Initialize environment for data generation pipeline
#' @keywords internal
#' @author Ghislain Durif
init_datagen_env <- function() {
    
    # clean environment
    tmp_dp <- list(
        ## project setup
        proj_name = NULL,        # project name
        proj_dir = NULL,         # project directory
        locus_type = NULL,       # "SNP" or "MSS"
        seq_mode = NULL,         # "IndSeq" or "PoolSeq"
        proj_file_list = NULL,   # content of the project
        file_modif = NULL,       # counter for project file modification 
                                 # (upload, new header, ...)
        ## data description
        model = NULL,           # historical model
        param = NULL,           # list of parameter values
        locus_desc = NULL,       # table of loci description
        n_group = NULL,         # number of loci group
        mss_prior = NULL,       # list of group priors for MSS data
        sample_sizes = NULL,    # table of sample sizes
        n_rep = NULL,           # number of replicates
        sex_ratio = NULL        # sex ratio in the simulation
    )
    
    ## clean up and define environment
    list2reactiveValues(tmp_dp, dp)
}

#' Reset environment for data generation pipeline
#' @keywords internal
#' @author Ghislain Durif
reset_datagen_env <- function() {
    # proj dir
    env$dp$proj_dir <- mk_proj_dir("diyabc_datagen")
}


#' Print content of diyabc-rf project sub-environment for debugging purpose
#' @keywords internal
#' @author Ghislain Durif
debug_ap <- function() {
    if(is.reactivevalues(env$ap)) {
        pprint(reactiveValuesToList(env$ap))
    } else {
        pprint(env$ap)
    }
}

#' Print content of metadata inside diyabc-rf project sub-environment 
#' for debugging purpose
#' @keywords internal
#' @author Ghislain Durif
debug_ap_metadata <- function() {
    if(is.reactivevalues(env$ap$metadata)) {
        pprint(reactiveValuesToList(env$ap$metadata))
    } else {
        pprint(env$ap$metadata)
    }
}

#' Print content of training set simulation setup inside diyabc-rf project 
#' sub-environment for debugging purpose
#' @keywords internal
#' @author Ghislain Durif
debug_ap_ts <- function() {
    if(is.reactivevalues(env$ap)) {
        pprint(reactiveValuesToList(env$ap$ts))
    } else {
        pprint(env$ap$ts)
    }
}

#' Print content of random forest setup inside diyabc-rf project 
#' sub-environment for debugging purpose
#' @keywords internal
#' @author Ghislain Durif
debug_ap_rf <- function() {
    if(is.reactivevalues(env$ap$rf)) {
        pprint(reactiveValuesToList(env$ap$rf))
    } else {
        pprint(env$ap$rf)
    }
}

#' Print content of data generation project sub-environment for debugging 
#' purpose
#' @keywords internal
#' @author Ghislain Durif
debug_dp <- function() {
    if(is.reactivevalues(env$ap)) {
        pprint(reactiveValuesToList(env$dp))
    } else {
        pprint(env$dp)
    }
}

#' Fill reactiveValues from package global environment with named list elements
#' @keywords internal
#' @author Ghislain Durif
#' @param named_list list of named elements to fill the reactiveValues `rval`
#' input arguments.
#' @param tag `reactiveValues` variable from package global environment to be  
#' filled with named elements from `named_list` input arguments.
list2reactiveValues <- function(named_list, tag) {
    # check
    if(length(names(named_list)) != length(named_list)) {
        stop("'named_list' input arg should be a named list")
    }
    # elements names
    name_vec <- names(named_list)
    # fill
    for(ind in 1:length(named_list)) {
        env[[as.character(substitute(tag))]][[name_vec[ind]]] <<-
            named_list[[ind]]
    }
}


#' Get value from named list in diyabc local environment
#' @keywords internal
#' @author Ghislain Durif
#' @param var1 named list in local environment.
#' @param var2 element of named list to get the value from.
#' @param env local environment where to get the value. By default it is 
#' diyabc local environment.
#' @return the value of element `var2` in list `var1`
getter <- function(var1, var2, env = diyabc_env) {
    return(env[[ as.character(substitute(var1)) ]][[ as.character(substitute(var2)) ]])
}

#' Set value in named list in diyabc local environment
#' @keywords internal
#' @author Ghislain Durif
#' @param value value to be set.
#' @param var1 named list in local environment.
#' @param var2 element of named list where the value will be stored.
#' @param env local environment where to get the value. By default it is 
#' diyabc local environment.
setter <- function(val, var1, var2, env = diyabc_env) {
    env[[ as.character(substitute(var1)) ]][[ as.character(substitute(var2)) ]] <<- val
}

#' Update project files
#' @keywords internal
#' @author Ghislain Durif
update_proj_file <- function(tag = "ap") {
    # increment file modification counter
    env[[tag]]$file_modif <- 
        ifelse(!is.null(env[[tag]]$file_modif), env[[tag]]$file_modif, 0) + 1
    # file list
    env[[tag]]$proj_file_list <- list.files(env[[tag]]$proj_dir)
}

#' Upload project files
#' @keywords internal
#' @author Ghislain Durif
upload_proj_file <- function(tag = "ap") {
    # increment file upload counter
    env[[tag]]$file_upload <- 
        ifelse(!is.null(env[[tag]]$file_upload), env[[tag]]$file_upload, 0) + 1
}
