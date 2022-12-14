#' Return diyabcGUI related program file name
#' @keywords internal
#' @author Ghislain Durif
prog_name <- function(prog = "diyabc") {
    out <- switch(
        prog,
        "diyabc" = "diyabc-RF",
        "abcranger" = "abcranger",
        stop("Bad input for 'prog' arg")
    )
    return(out)
}

#' Find diyabcGUI related binary files
#' @keywords internal
#' @author Ghislain Durif
find_bin <- function(prog = "diyabc") {
    # check input
    if(!prog %in% c("diyabc", "abcranger")) {
        stop("Wrong input")
    }
    # binary directory
    path <- bin_dir()
    # platform
    os_id <- get_os()
    # binary file
    bin_name <- str_c(prog_name(prog), os_id, sep = "-")
    # check if bin file exists
    if(!any(str_detect(list.files(path), bin_name))) {
        stop(str_c("Missing", bin_name, "binary file", sep = " "))
    }
    # find latest binary file
    bin_candidates <- list.files(path)[str_detect(list.files(path), bin_name)]
    if(length(bin_candidates) == 0) {
        stop(str_c("Missing", bin_name, "binary file", sep = " "))
    }
    latest_bin <- which.max(
        file.info(file.path(path, bin_candidates))$mtime
    )
    bin_file <- file.path(path, bin_candidates[latest_bin])
    # output
    return(bin_file)
}


#' Find which OS is running
#' @keywords internal
#' @author Ghislain Durif
get_os <- function() {
    # get OS id given by R
    os_id <- str_extract(string = R.version$os, 
                         pattern = "mingw32|windows|darwin|linux")
    # check if error
    if(is.na(os_id)) {
        stop(str_c("Issue with os:", os_id, "not supported", sep = " "))
    }
    # return OS name
    os_name <- switch(
        os_id,
        "linux"  = "linux",
        "darwin" = "macos",
        "mingw32" = "windows",
        "windows" = "windows",
    )
    return(os_name)
}

#' Download latest diyabcGUI related binary files if missing
#' @keywords internal
#' @author Ghislain Durif
#' @param prog string, name of the program to download, eligible name are
#' `"diyabc-RF"` and `"abcranger"`.
#' @return integer value, `0` if download succeeded, `1` if download failed,
#' `-1` if latest version is already here.
#' @importFrom fs file_chmod
#' @importFrom jsonlite fromJSON
#' @export
dl_latest_bin <- function(prog = "diyabc") {
    # check
    if(!prog %in% c("diyabc", "abcranger")) {
        stop("Wrong 'prog' input argument")
    }
    
    # bin directory
    path <- bin_dir()
    
    # platform
    os_id <- get_os()
    
    # release url
    release_url <- str_c(
        "https://api.github.com/repos/diyabc", 
        prog,
        "releases/latest",
        sep = "/"
    )
    
    # check latest release info
    release_info <- fromJSON(release_url)
    
    # get latest release list
    release <- release_info$assets[,c("name", "browser_download_url")]
    
    # check if file in release
    if(nrow(release) < 1) {
        stop(str_c(
            "Issue with files available at", release_url, ",",
            "please contact DIYABC-RF support.",
            sep = " "
        ))
    }
    
    # select release for current OS
    release <- subset(release, str_detect(release$name, os_id))
    
    # check if release available for current OS
    if(nrow(release) != 1) {
        stop(str_c(
            prog, "binary file is not available for", os_id, "OS at",
            release_url, ",",
            "please contact DIYABC-RF support.",
            sep = ""
        ))
    }
    
    # already existing binary file
    existing_bin_files <- list.files(path)
    
    # download release
    check <- 1
    bin_name <- release$name
    bin_url <- release$browser_download_url
    
    # check if bin file already available locally
    if(!bin_name %in% existing_bin_files) {
        # avoid blacklisting
        Sys.sleep(2)
        # dl
        check <- download.file(
            bin_url, 
            destfile = file.path(path, bin_name),
            mode = "wb"
        )
    } else {
        check <- -1
        warning(str_c(
            "The latest release", bin_name, 
            "was already downloaded.", sep = " "
        ))
    }
    
    # zip extraction for diyabc on Windows
    zip_files <- list.files(path, pattern = "\\.zip$")
    if(length(zip_files) > 0) {
        latest_zip <- which.max(file.info(file.path(path, zip_files))$mtime)
        tmp <- utils::unzip(
            file.path(path, zip_files[latest_zip]), 
            exdir = path
        )
        if(length(tmp) == 0) {
            stop(str_c(
                "Issue when unzipping", zip_files[latest_zip], sep = " "
            ))
        }
        fs::file_delete(file.path(path, zip_files))
    }
    
    # set up rights
    bin_files <- list.files(path, pattern = prog)
    fs::file_chmod(file.path(path, bin_files), "a+rx")
    
    # output
    return(check)
}

#' Download all latest diyabcGUI related binary files if missing
#' @keywords internal
#' @author Ghislain Durif
#' @export
dl_all_latest_bin <- function() {
    check_diyabc <- dl_latest_bin("diyabc")
    check_abcranger <- dl_latest_bin("abcranger")
    return(lst(check_diyabc, check_abcranger))
}

#' Custom print
#' @keywords internal
#' @author Ghislain Durif
pprint <- function(...) {
    print(str_c("--- content of ",deparse(substitute(...))))
    # message(as.character(...))
    print(...)
}

#' Reset sink (console output redirection)
#' @keywords internal
#' @author Ghislain Durif
reset_sink <- function() {
    if(sink.number() > 0) {
        sink(type = "message")
        sink()
    }
}

#' Logging function for debugging
#' @keywords internal
#' @author Ghislain Durif
logging <- function(...) {
    if(get_option("verbose"))
        print(str_c(..., sep = " ", collapse = " "))
}

#' Enable logging verbosity
#' @keywords internal
#' @author Ghislain Durif
#' @export
enable_logging <- function() {
    # current option status
    diyabcGUI_options <- getOption("diyabcGUI")
    # enable logging
    diyabcGUI_options$verbose <- TRUE
    # save change
    options("diyabcGUI" = diyabcGUI_options)
}

#' Disable logging verbosity
#' @keywords internal
#' @author Ghislain Durif
#' @export
disable_logging <- function() {
    # current option status
    diyabcGUI_options <- getOption("diyabcGUI")
    # enable logging
    diyabcGUI_options$verbose <- FALSE
    # save change
    options("diyabcGUI" = diyabcGUI_options)
}

#' Set up diyabcGUI options
#' @keywords internal
#' @author Ghislain Durif
#' @param ncore integer, number of cores to used for parallel computations, 
#' default is half available cores.
#' @param log_file character string, filename where to write log messages.
#' @param simu_loop_size integer, batch size for simulation loop, default 
#' is 100.
#' @param image_ext string, possible ggplot extensions among `"eps"`, `"ps"`, 
#' `"tex"`, `"pdf"`, `"jpeg"`, `"tiff"`, `"png"`, `"bmp"`, `"svg"`
#' @param verbose boolean, enable/disable logging verbosity, default is FALSE.
#' @export
set_diyabcGUI_options <- function(
    ncore = parallel::detectCores() - 2,
    log_file = file.path(tempdir(check=TRUE), "diyabc_rf_gui.log"),
    simu_loop_size = 5, 
    image_ext = "png",
    verbose = TRUE
) {
    # existing diyabcGUI options ?
    diyabcGUI_options <- getOption("diyabcGUI")
    # setup options
    diyabcGUI_options$ncore <- as.integer(ncore)
    diyabcGUI_options$log_file <- as.character(log_file)
    diyabcGUI_options$simu_loop_size <- as.integer(simu_loop_size)
    diyabcGUI_options$image_ext <- as.character(image_ext)
    diyabcGUI_options$verbose <- as.logical(verbose)
    # set up package options
    options("diyabcGUI" = diyabcGUI_options)
}

#' Get current diyabcGUI option states
#' @keywords internal
#' @author Ghislain Durif
#' @export
get_option <- function(option_name) {
    # current option state
    diyabcGUI_options <- getOption("diyabcGUI")
    # check input
    if(! option_name %in% names(diyabcGUI_options))
        stop("Bad input for 'option_name' arg")
    # output
    return(diyabcGUI_options[[ option_name ]])
}
