#' Read and parse headerRF.txt and header.txt file
#' @keywords internal
#' @author Ghislain Durif
#' @description
#' Content: see doc
#' @param file_name string, (server-side) path to a headersim file.
#' @param file_type string, MIME file type.
#' @param locus_type string, "snp" or "mss"
#' @param expected_npop integer, number of populations in the dataset.
read_header <- function(file_name, file_type, locus_type = "snp", 
                        expected_npop = NULL) {
    
    # init output
    out <- list(
        msg = list(), valid = TRUE,
        data_file = NULL, locus_desc = NULL, 
        n_param = NULL, n_prior = NULL, n_stat = NULL, 
        cond_list = NULL, prior_list = NULL, 
        n_group = NULL, group_prior_list = NULL, 
        n_scen = NULL, scenario_list = NULL, n_param_list = NULL,
        simu_mode = NULL,
        header_file = NULL
    )
    
    current_line <- 0
    
    # check file_name
    tmp <- check_file_name(file_name)
    if(!tmp) {
        out$valid <- FALSE
        msg <- tagList("Invalid file name")
        out$msg <- append(out$msg, list(msg))
    }
    
    # check file_type
    if(file_type != "text/plain") {
        out$valid <- FALSE
        msg <- tagList("Wrong file type")
        out$msg <- append(out$msg, list(msg))
    }
    
    # continue ?
    if(!out$valid) {
        return(out)
    }
    
    ## HEADER FILE NAME
    out$header_file <- basename(file_name)
    
    ## HEADER FILE CONTENT
    header <- readLines(file_name, warn = FALSE)
    
    ## data file
    out$data_file <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    
    ## number of parameters and statistics
    pttrn <- "^[0-9]+ parameters and [0-9]+ summary statistics$"
    strng <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    if(!str_detect(strng, pttrn)) {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with line", tags$b(as.character(current_line)), 
            "that should match the pattern", tags$code(pttrn)
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    # # number of parameter is not trustworthy on this line
    # pttrn <- "[0-9]+(?= parameters)"
    # out$n_param <- as.integer(str_extract(strng, pttrn))
    pttrn <- "[0-9]+(?= summary statistics)"
    out$n_stat <- as.integer(str_extract(strng, pttrn))
    
    ## empty line
    strng <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    if(strng != "") {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with line", tags$b(as.character(current_line)), 
            "that should be empty"
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    ## scenarios
    pttrn <- "^[0-9]+ scenarios:( [0-9]+)+ ?$"
    strng <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    # find section
    if(!str_detect(strng, pttrn)) {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with line", tags$b(as.character(current_line)), 
            "that should match the pattern", tags$code(pttrn)
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    ## scenario config
    pttrn <- "[0-9]+(?= scenarios:)"
    out$n_scen <- as.integer(str_extract(strng, pttrn))
    pttrn <- "(?<= )[0-9]+"
    nrow_per_scenario <- as.integer(unlist(str_extract_all(strng, pttrn)))
    ## extract scenarii
    row_seq <- cumsum(c(1, nrow_per_scenario+1))
    parsed_scenario_list <- lapply(
        split(
            header[(min(row_seq):(max(row_seq)-1))], 
            rep(seq(row_seq), diff(c(row_seq, max(row_seq))))
        ), 
        function(content) parse_header_scenario(content, expected_npop)
    )
    # next
    header <- header[-(1:(max(row_seq)-1))]
    current_line <- current_line + max(row_seq) - 1
    # check extracted scnenarii
    scen_check <- unlist(lapply(
        parsed_scenario_list, function(item) item$valid
    ))
    scen_id <- unlist(lapply(
        parsed_scenario_list, function(item) item$id
    ))
    if(!all(scen_check)) {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with format of following scenarii:", 
            str_c(scen_id[!scen_check], collapse = ", ")
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    # number of parameters per scenario
    out$n_param_list <- unlist(unname(lapply(
        parsed_scenario_list, function(item) item$n_param
    )))
    # extract raw scenario list
    out$scenario_list <- unlist(unname(lapply(
        parsed_scenario_list, function(item) item$scenario
    )))
    # total number of parameters
    out$n_param <- length(unique(unlist(unname(lapply(
        parsed_scenario_list, function(item) item$param
    )))))
    
    ## empty line
    strng <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    if(strng != "") {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with line", tags$b(as.character(current_line)), 
            "that should be empty"
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    ## historical parameters
    pttrn <- "^historical parameters priors \\([0-9]+,[0-9]+\\)$"
    strng <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    # find section
    if(!any(str_detect(strng, pttrn))) {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with line", tags$b(as.character(current_line)), 
            "that should match the pattern", tags$code(pttrn)
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    # number of priors
    pttrn <- "(?<= \\()[0-9]+"
    out$n_prior <- as.integer(str_extract(strng, pttrn))
    # number of conditions
    pttrn <- "[0-9]+(?=\\)$)"
    out$n_cond <- as.integer(str_extract(strng, pttrn))
    
    ## parameter config
    # extract priors
    out$prior_list <- header[1:out$n_prior]
    header <- header[-(1:out$n_prior)]
    current_line <- current_line + out$n_prior
    # check extracted priors
    prior_check <- unlist(lapply(out$prior_list, check_header_prior))
    if(!all(prior_check)) {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with format of parameter priors at lines:", 
            str_c(which(!prior_check) + current_line, collapse = ", ")
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    # extract conditions
    if(out$n_cond > 0) {
        
        out$cond_list <- header[1:out$n_cond]
        header <- header[-(1:out$n_cond)]
        current_line <- current_line + out$n_cond
        # check extracted conds
        cond_check <- unlist(lapply(out$cond_list, check_header_cond))
        if(!all(cond_check)) {
            out$valid <- FALSE
            msg <- tagList(
                "Issue with format of parameter conditions at lines:", 
                str_c(
                    which(!cond_check) + current_line - out$n_cond, 
                    collapse = ", "
                )
            )
            out$msg <- append(out$msg, list(msg))
            return(out)
        }
        
        # generation mode
        pttrn <- "DRAW UNTIL"
        out$simu_mode <- header[1]
        header <- header[-1]
        current_line <- current_line + 1
        if(out$simu_mode != pttrn) {
            out$valid <- FALSE
            msg <- tagList(
                "Missing 'DRAW UNTIL' after conditions at lines:", 
                as.character(current_line+1)
            )
            out$msg <- append(out$msg, list(msg))
            return(out)
        }
        
    }
    
    ## empty line (and check for unnecessary simulation mode)
    strng <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    if(strng != "") {
        if(strng == "DRAW UNTIL") {
            out$valid <- FALSE
            msg <- tagList(
                "Issue with line", tags$b(as.character(current_line)), 
                "unnecessary 'DRAW UNTIL'"
            )
            out$msg <- append(out$msg, list(msg))
        } else {
            out$valid <- FALSE
            msg <- tagList(
                "Issue with line", tags$b(as.character(current_line)), 
                "that should be empty"
            )
            out$msg <- append(out$msg, list(msg))
        }
        return(out)
    }
    
    ## loci description
    pttrn <- "^loci description \\([0-9]+\\)$"
    strng <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    # find section
    if(!any(str_detect(strng, pttrn))) {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with line", tags$b(as.character(current_line)), 
            "that should match the pattern", tags$code(pttrn)
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    # number of loci description
    pttrn <- "(?<=^loci description \\()[0-9]+"
    out$n_locus_desc <- as.integer(str_extract(strng, pttrn))
    
    # extract loci description
    out$locus_desc <- header[1:out$n_locus_desc]
    header <- header[-(1:out$n_locus_desc)]
    current_line <- current_line + out$n_locus_desc
    # check extracted loci description
    locus_desc_check <- unlist(lapply(
        out$locus_desc, 
        check_header_locus_desc, type = locus_type
    ))
    if(!all(locus_desc_check)) {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with format of locus description at lines:", 
            str_c(which(!locus_desc_check) + current_line, collapse = ", ")
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    ## empty line
    strng <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    if(strng != "") {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with line", tags$b(as.character(current_line)), 
            "that should be empty"
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    ## group prior (for microsat/sequence)
    if(locus_type == "mss") {
        
        pttrn <- "^group priors \\([0-9]+\\)$"
        strng <- header[1]
        header <- header[-1]
        current_line <- current_line + 1
        # find section
        if(!any(str_detect(strng, pttrn))) {
            out$valid <- FALSE
            msg <- tagList(
                "Issue with line", tags$b(as.character(current_line)), 
                "that should match the pattern", tags$code(pttrn)
            )
            out$msg <- append(out$msg, list(msg))
            return(out)
        }
        
        # number of group prior
        pttrn <- "(?<=^group priors \\()[0-9]"
        out$n_group <- as.integer(str_extract(strng, pttrn))
        
        # find next section
        tmp_current_line <- current_line
        end_sec <- head(which(header == ""), 1)
        content <- header[1:(end_sec-1)]
        header <- header[-(1:(end_sec-1))]
        current_line <- current_line + end_sec - 1
        
        # extract group prior
        group_prior_check <- parse_header_group_prior(
            content, out$n_group, tmp_current_line
        )
        
        if(!group_prior_check$valid) {
            out$valid <- FALSE
            msg <- tagList(
                "Issue with format of group prior around line ", 
                tags$b(as.character(group_prior_check$current_line))
            )
            out$msg <- append(out$msg, list(msg))
            return(out)
        }
        
        current_line <- group_prior_check$current_line
        out$group_prior_list <- group_prior_check$group_prior
        
        ## empty line
        strng <- header[1]
        header <- header[-1]
        current_line <- current_line + 1
        if(strng != "") {
            out$valid <- FALSE
            msg <- tagList(
                "Issue with line", tags$b(as.character(current_line)), 
                "that should be empty"
            )
            out$msg <- append(out$msg, list(msg))
            return(out)
        }
    }
    
    ## group summary statistics
    pttrn <- "^group summary statistics \\([0-9]+\\)$"
    strng <- header[1]
    header <- header[-1]
    current_line <- current_line + 1
    # find section
    if(!any(str_detect(strng, pttrn))) {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with line", tags$b(as.character(current_line)), 
            "that should match the pattern", tags$code(pttrn)
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    # number of summary stats
    pttrn <- "(?<=^group summary statistics \\()[0-9]+"
    tmp_n_stat <- sum(as.integer(str_extract(strng, pttrn)), na.rm = TRUE)
    # check
    if(out$n_stat != tmp_n_stat) {
        out$valid <- FALSE
        msg <- tagList(
            "Issue with line", tags$b(as.character(current_line)), 
            "the number of summary statistics is different",
            "from the number given in line 2"
        )
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    ##
    # TODO: parse end of file
    
    # output
    return(out)
}


#' Parse scenario in header file
#' @keywords internal
#' @author Ghislain Durif
#' @description
#' Content: see doc
#' @param content string vector, scenario description
#' @param expected_npop integer, number of populations in the dataset.
parse_header_scenario <- function(content, expected_npop = NULL) {
    
    # init output
    out <- list(
        valid = TRUE,
        id = NULL, n_param = NULL,
        prior = NULL, scenario = NULL
    )
    
    # description (1st line)
    strng <- content[1]
    pttrn <- str_c("^scenario [0-9]+ \\[", num_regex(), "\\] \\([0-9]+\\)$")
    if(!str_detect(strng, pttrn)) {
        out$valid <- FALSE
        return(out)
    }
    
    # scenario id
    pttrn <- "(?<=^scenario )[0-9]+"
    out$id <- as.integer(str_extract(strng, pttrn))
    # scenario prior
    pttrn <- str_c("(?<= \\[)", num_regex(), "(?=\\] )")
    out$prior <- as.numeric(str_extract(strng, pttrn))
    # number of parameters in scenario
    pttrn <- "(?<= \\()[0-9]+(?=\\)$)"
    out$n_param <- as.integer(str_extract(strng, pttrn))
    
    ## scenario
    out$scenario <- str_c(content[-1], collapse = "\n")
    
    # check scenario
    scen_check <- parse_scenario(out$scenario, expected_npop)
    if(!scen_check$valid) {
        out$valid <- FALSE
        return(out)
    }
    
    # parameters
    out$param <- as.character(c(
        scen_check$Ne_param, scen_check$time_param, scen_check$rate_param
    ))
    
    ## output
    return(out)
}


#' Parse scenario in header file
#' @keywords internal
#' @author Ghislain Durif
#' @description
#' Content: see doc
#' @param content string vector, scenario description
parse_header_group_prior <- function(content, n_group, current_line) {
    
    # init output
    out <- list(
        valid = FALSE, ind = NULL, group_prior = NULL, mss_type = NULL,
        current_line = current_line
    )
    
    # loop over group priors
    for(ind in 1:n_group) {
        # which group
        out$ind <- ind
        # description (1st line)
        pttrn <- str_c("^group G[0-9]+ \\[(M|S)\\]$")
        strng <- content[1]
        content <- content[-1]
        out$current_line <- out$current_line + 1
        if(!str_detect(strng, pttrn)) {
            out$valid <- FALSE
            return(out)
        } else {
            group_prior_head <- strng
            # locus type
            pttrn <- "(?<=\\[)(M|S)(?=\\])"
            out$mss_type[ind] <- str_extract(strng, pttrn)
            n_line <- switch (
                out$mss_type[ind],
                "M" = 6,
                "S" = 7,
                NA
            )
            out$valid <- check_header_group_prior(
                head(content, n_line), type = out$mss_type[ind]
            )
            if(!out$valid) {
                return(out)
            }
            out$group_prior[ind] <- str_c(
                c(group_prior_head, head(content, n_line)), collapse = "\n"
            )
            content <- content[-(1:n_line)]
            out$current_line <- out$current_line + n_line
        }
    }
    
    ## output
    return(out)
}



#' Read and parse statobsRF.txt file
#' @keywords internal
#' @author Ghislain Durif
#' @description
#' Content: see doc
#' @param file_name string, (server-side) path to a headersim file.
#' @param file_type string, MIME file type.
#' @param n_stat integer, number of summary statistics in reftable.
read_statobs <- function(file_name, file_type, n_stat) {
    
    # init output
    out <- list(msg = list(), valid = TRUE)
    
    # check file_name
    tmp <- check_file_name(file_name)
    if(!tmp) {
        out$valid <- FALSE
        msg <- tagList("Invalid file name")
        out$msg <- append(out$msg, list(msg))
    }
    
    # check file_type
    if(file_type != "text/plain") {
        out$valid <- FALSE
        msg <- tagList("Wrong file type")
        out$msg <- append(out$msg, list(msg))
    }
    
    # continue ?
    if(!out$valid) {
        return(out)
    }
    
    # try reading it
    tmp <- tryCatch(
        read.table(file_name), 
        error = function(e) return(NULL)
    )
    
    if(is.null(tmp)) {
        out$valid <- FALSE
        msg <- tagList("Issue with statobs file format")
        out$msg <- append(out$msg, list(msg))
        return(out)
    }
    
    # check number of rows and columns
    if(nrow(tmp) != 2) {
        out$valid <- FALSE
        msg <- tagList(
            "The statobs file is supposed to contain two lines:",
            "one with the names of the summary statistics,",
            "and a second with the corresponding values",
            "computed on the dataset."
        )
        out$msg <- append(out$msg, list(msg))
    }
    
    if(ncol(tmp) != n_stat) {
        out$valid <- FALSE
        msg <- tagList(
            "The number of summary statistics in the statobs file",
            "does not correspond to the number of summary statistics",
            "in the reftable file."
        )
        out$msg <- append(out$msg, list(msg))
    }
    
    # output
    return(out)
}

#' Read and parse reftableRF.bin file
#' @keywords internal
#' @author Ghislain Durif
#' @author Fran??ois-David Collin
#' @description
#' Content: see doc
#' @param file_name string, (server-side) path to a headersim file.
#' @param file_type string, MIME file type.
read_reftable <- function(file_name, file_type) {
    
    # init output
    out <- list(
        msg = list(), valid = TRUE, 
        n_rec = NULL, n_scen = NULL, n_rec_scen = NULL, n_param_list = NULL, 
        n_stat = NULL
    )
    
    # check file_name
    tmp <- check_file_name(file_name)
    if(!tmp) {
        out$valid <- FALSE
        msg <- tagList("Invalid file name")
        out$msg <- append(out$msg, list(msg))
    }
    
    # check file_type
    if(file_type != "application/octet-stream") {
        out$valid <- FALSE
        msg <- tagList("Wrong file type")
        out$msg <- append(out$msg, list(msg))
    }
    
    # continue ?
    if(!out$valid) {
        return(out)
    }
    
    ## Reftable feed
    # Stream from reftable file
    to_read = file(file_name,"rb")
    # number of records
    out$n_rec <- readBin(to_read, integer(), endian = "little")
    # number of scenarios
    out$n_scen <- readBin(to_read, integer(), endian = "little")
    # number of records for each scenario
    out$n_rec_scen <- readBin(to_read, integer(), n = out$n_scen, 
                              endian = "little")
    # number of used parameters (non constant)
    out$n_param_list <- readBin(to_read, integer(), n = out$n_scen, 
                                endian = "little")
    # number of stats
    out$n_stat <- readBin(to_read, integer(), endian = "little")
    
    # close stream
    close(to_read)
    
    # output
    return(out)
}