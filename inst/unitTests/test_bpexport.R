library(doParallel)                     # FIXME: unload?

.fork_not_windows <- function(expected, expr)
{
    err <- NULL
    obs <- tryCatch(expr, error=function(e) {
        if (!all(grepl("fork clusters are not supported on Windows",
                       conditionMessage(e))))
            err <<- conditionMessage(e)
        expected
    })
    checkTrue(is.null(err))
    checkIdentical(expected, obs)
}

test_bplapply_Params <- function()
{
    params <- list(serial=SerialParam(),
                   mc=MulticoreParam(2),
                   snow0=SnowParam(2, "FORK"),
                   snow1=SnowParam(2, "PSOCK"),
                   dopar=DoparParam(),
                   batchjobs=BatchJobsParam(),
                   dopar=DoparParam())

    dop <- registerDoParallel(cores=2)
    ## FIXME: restore previously registered back-end?

    ## Defune a function that uses a variable from outside its
    ## definition
    export.var <- 10
    func <- function(a) sqrt(a+export.var)
    
    x <- 1:10
    expected <- lapply(x, func)
    for (ptype in names(params)) {
        .fork_not_windows(expected, {
            ## Try all methods of exporting the variable
            bpexport(x, "export.var")
            bpexport(x, export.var=export.var)
            bpexport(x, export.var)
            bplapply(x, myfunc, BPPARAM=params[[ptype]])
        })
    }
    TRUE
}
