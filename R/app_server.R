#' Shiny app server function
#' @keywords internal
#' @description
#' FIXME
#' @details
#' FIXME
#' @author Ghislain Durif
#' @param input app input.
#' @param output app output.
#' @param session shiny session.
#' @importFrom shinyhelper observe_helpers
#' @return None
#' @export
diyabc_server <- function(input, output, session) {
    ## logging
    log_info("Starting diyabc-RF-GUI app")
    shiny::onStop(function() {
        log_info("Exiting diyabc-RF-GUI app")
    })
    ## help
    observe_helpers(session, help_dir = help_dir(), withMathJax = TRUE)
    ## init
    local <- reactiveValues(init = NULL)
    observeEvent(local$init, {
        init_diyabcrf_env()
        init_datagen_env()
    }, ignoreNULL = FALSE)
    ## index server function
    index_server(input, output, session)
}