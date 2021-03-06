\name{SnowParam-class}
\Rdversion{1.1}
\docType{class}

% Class 
\alias{SnowParam}
\alias{SnowParam-class}

% Control
\alias{snowWorkers}
\alias{bpbackend,SnowParam-method}
\alias{bpbackend<-,SnowParam,cluster-method}
\alias{bpisup,SnowParam-method}
\alias{bpstart,SnowParam-method}
\alias{bpstop,SnowParam-method}
\alias{bpworkers,SnowParam-method}
\alias{bpworkers<-,SnowParam,numeric-method}
\alias{bpworkers<-,SnowParam,character-method}

% Accessors
\alias{bplog}
\alias{bplog<-}
\alias{bplog,SnowParam-method}
\alias{bplog<-,SnowParam,logical-method}
\alias{bpthreshold}
\alias{bpthreshold<-}
\alias{bpthreshold,SnowParam-method}
\alias{bpthreshold<-,SnowParam,character-method}
\alias{bplogdir}
\alias{bplogdir<-}
\alias{bplogdir,SnowParam-method}
\alias{bplogdir<-,SnowParam,character-method}
\alias{bpresultdir}
\alias{bpresultdir<-}
\alias{bpresultdir,SnowParam-method}
\alias{bpresultdir<-,SnowParam,character-method}

% Other methods
\alias{coerce,SOCKcluster,SnowParam-method}
\alias{coerce,spawnedMPIcluster,SnowParam-method}
\alias{show,SnowParam-method}

% Other functions
\alias{bpslaveLoop}
\alias{bprunMPIslave}
\alias{bpok}

\title{Enable simple network of workstations (SNOW)-style parallel evaluation}

\description{

  This class is used to parameterize simple network of workstations
  (SNOW) parallel evaluation on one or several physical computers.
  \code{snowWorkers()} chooses the number of workers based on global
  user preference (\code{options(mc.cores=...)}), or the minimum of 8
  and the number of detected cores (\code{detectCores()}).

}

\usage{

## constructor 
## ------------------------------------

SnowParam(workers = snowWorkers(), type=c("SOCK", "MPI", "FORK"),
          tasks = 0L, catch.errors=TRUE, stop.on.error = FALSE, 
          progressbar = FALSE, log = FALSE, threshold = "INFO", 
          logdir = NA_character_, resultdir = NA_character_, ...)

## coercion 
## ------------------------------------

\S4method{coerce}{SOCKcluster,SnowParam}(from, to)
\S4method{coerce}{spawnedMPIcluster,SnowParam}(from, to)

## detect workers 
## ------------------------------------

snowWorkers()
}

\details{

  \code{SnowParam} is used for distributed memory computing and supports
  2 cluster types: \sQuote{SOCK} (default) and \sQuote{MPI}. The \code{SnowParam}
  builds on infrastructure in the \code{snow} and \code{parallel}
  packages and provides the additional features of error handling, logging
  and writing out results.

  \describe{
    \item{error handling:}{
      Two flags control error handling: \code{catch.errors} and 
      \code{stop.on.error}.
      \itemize{
        \item \code{catch.errors} determines whether errors are caught and
              returned with other results. When \code{TRUE}, all computations 
              are attempted and output contains both errors and successfully 
              completed results. When \code{FALSE}, the job is terminated as 
              soon as the first error is hit and only the error message is 
              returned (no results); this is the default behavior of the 
              parent packages, e.g., \code{parallel}, \code{snow}, 
              \code{foreach}.

        \item \code{stop.on.error} controls whether the job stops after an 
              error is thrown. When \code{TRUE}, the output contains all 
              successfully completed results up to and including the error. 
              Unlike \code{catch.errors == TRUE}, when 
              \code{stop.on.error == TRUE} all computations stop once the 
              error is hit. When \code{FALSE}, the job runs to completion 
              and successful results are returned along with any error messages.
      }
    \code{catch.errors} and \code{stop.on.error} cannot both be \code{TRUE}.
    }
    \item{logging:}{
      Logging is implemented on the workers with the \code{futile.logger}
      package. The argument to the constructor is \code{log} and the value is
      accessed with \code{bplog(BPPARAM)}. When \code{log == TRUE}, cluster
      workers use a script in the \code{BiocParallel} package instead of
      \code{snow}. This modified script captures warning and error messages and
      collects additional task statistics such as gc output and node name. When
      \code{log == TRUE} \code{catch.errors} must also be TRUE.
 
      Any \code{futile.logger} messages the user provides in their function will
      be captured by the logging mechanism. Messages are returned real-time
      (i.e., as each tasks completes) instead of after all jobs have finished.
    }
    \item{log and result files:}{
      Results and logs can be written to a file instead of returned to
      the workspace. Writing to files is done from the master as each task 
      completes. Options can be set with the \code{logdir} and 
      \code{resultdir} fields in the constructor or with the accessors,
      \code{bplogdir} and \code{bpresultdir}. 
    }
  }

  NOTE: The \code{PSOCK} cluster from the \code{parallel} package does not 
  support cluster options \code{scriptdir} and \code{useRscript}. Because
  these options are needed to use an alternate worker script, \code{PSOCK} 
  is not supported in \code{SnowParam}.

}

\section{Constructor}{

  \describe{
    \item{}{
      \code{SnowParam(workers = snowWorkers(), type=c("SOCK", "MPI"),
                      tasks = 0L, catch.errors = TRUE, stop.on.error = FALSE,
                      progressbar = FALSE, log = FALSE, threshold = "INFO", 
                      logdir = NA_character_, resultdir = NA_character_, ...)}:

        Return an object representing a SNOW cluster. The cluster is not
        created until \code{bpstart} is called. Named arguments in \code{...} 
        are passed to \code{makeCluster}.
    }
  }

}

\arguments{

  \item{workers}{
    \code{integer(1)} Number of workers. Defaults to all cores available as
    determined by \code{detectCores}. For a \code{SOCK} cluster \code{workers}
    can be a \code{character()} vector of host names.
  }
  \item{type}{
    \code{character(1)} Type of cluster to use. Possible values are
    \code{SOCK} (default) and \code{MPI}. Instead of \code{type=FORK} use
    \code{MulticoreParam}.
  }
  \item{tasks}{
    \code{integer(1)}. The number of tasks per job. \code{value} must be a 
    scalar integer >= 0L.
 
    In this documentation a job is defined as a single call to a function,
    \code{bplapply}, \code{bpmapply} etc. A task is the division of the \code{X}
    argument into chunks. When \code{tasks == 0} (default), \code{X} is divided
    by the number of workers. This approach distributes \code{X} in
    (approximately) equal chunks.
 
    A \code{tasks} value of > 0 dictates the total number of tasks. Values
    can range from 1 (all of \code{X} to a single worker) to the length of 
    \code{X} (each element of \code{X} to a different worker). 
 
    When the length of \code{X} is less than the number of workers each
    element of \code{X} is sent to a worker and \code{tasks} is ignored.
  } 
  \item{catch.errors}{
    \code{logical(1)} Enable the catching of errors and warnings.
  }
  \item{stop.on.error}{
    \code{logical(1)} Enable stop on error.
  }
  \item{progressbar}{
    \code{logical(1)} Enable progress bar (based on plyr:::progress_text).
  }
  \item{log}{
    \code{logical(1)} Enable logging.
  }
  \item{threshold}{
    \code{character(1)} Logging threshold as defined in \code{futile.logger}.
  }
  \item{logdir}{
    \code{character(1)} Log files directory. When not provided, log
    messages are returned to stdout.
  }
  \item{resultdir}{
    \code{character(1)} Job results directory. When not provided, results
    are returned as an \R{} object (list) to the workspace.
  }
  \item{\dots}{
    Additional arguments passed to \code{\link[snow]{makeCluster}}
  }
  \item{from}{
    A \code{SOCKcluster} or \code{spawnedMPIcluster} instance created
    with \code{makeCluster} in the \code{parallel} or \code{snow} package.
    Applicable to \code{coerce} methods only.
  } 
  \item{to}{
    \code{character(1)} \dQuote{SnowParam}. Applicable to \code{coerce}
    methods only.
  }

}

\section{Accessors: Logging and results}{

  In the following code, \code{x} is a \code{SnowParam} object.
  \describe{
    \item{}{
      \code{bpprogressbar(x, ...)}, \code{bpprogressbar(x) <- value}: 
      Get or set the value to enable text progress bar. 
      \code{value} must be a \code{logical(1)}.
    }
    \item{}{
      \code{bplog(x, ...)}, \code{bplog(x) <- value}: 
      Get or set the value to enable logging. \code{value} must be a
      \code{logical(1)}.
    }
    \item{}{
      \code{bpthreshold(x, ...)}, \code{bpthreshold(x) <- value}: 
      Get or set the logging threshold. \code{value} must be a
      \code{character(1)} string of one of the levels defined in the
      \code{futile.logger} package: \dQuote{TRACE}, \dQuote{DEBUG},
      \dQuote{INFO}, \dQuote{WARN}, \dQuote{ERROR}, or \dQuote{FATAL}.
    }
    \item{}{
      \code{bplogdir(x, ...)}, \code{bplogdir(x) <- value}: 
      Get or set the directory for the log file. \code{value} must be a
      \code{character(1)} path, not a file name. The file is written out as
      BPLOG.out. If no \code{logdir} is provided and \code{bplog=TRUE} log
      messages are sent to stdout.
    }
    \item{}{
      \code{bpresultdir(x, ...)}, \code{bpresultdir(x) <- value}: 
      Get or set the directory for the result files. \code{value} must be a
      \code{character(1)} path, not a file name. Separate files are written for
      each job with the prefix TASK (e.g., TASK1, TASK2, etc.).  When no
      \code{resultdir} is provided the results are returned to the session as
      \code{list}.
    }
  }

}

\section{Accessors: Back-end control}{

  In the code below \code{x} is a \code{SnowParam} object.  See the
  ?\code{BiocParallelParam} man page for details on these accessors.
  \describe{
    \item{}{\code{bpworkers(x, ...)}, \code{bpworkers(x) <- value}}
    \item{}{\code{bptasks(x, ...)}, \code{bptasks(x) <- value}}
    \item{}{\code{bpstart(x, ...)}}
    \item{}{\code{bpstop(x, ...)}}
    \item{}{\code{bpisup(x, ...)}}
    \item{}{\code{bpbackend(x, ...)}, \code{bpbackend(x) <- value}}
  }

} 

\section{Accessors: Error Handling}{

  In the code below \code{x} is a \code{SnowParam} object. See the
  ?\code{BiocParallelParam} man page for details on these accessors.
  \describe{
    \item{}{\code{bpcatchErrors(x, ...)}, \code{bpcatchErrors(x) <- value}}
    \item{}{\code{bpstopOnError(x, ...)}, \code{bpstopOnError(x) <- value}}
  }

}

\section{Methods: Evaluation}{

  In the code below \code{BPPARAM} is a \code{SnowParam} object.
  Full documentation for these functions are on separate man pages: see
  ?\code{bpmapply}, ?\code{bplapply}, ?\code{bpvec}, ?\code{bpiterate} and
  ?\code{bpaggregate}.
  \describe{
    \item{}{ 
      \code{bpmapply(FUN, ..., MoreArgs=NULL, SIMPLIFY=TRUE, 
                     USE.NAMES=TRUE, BPPARAM=bpparam())}
    }
    \item{}{
      \code{bplapply(X, FUN, ..., BPPARAM=bpparam())}
    }
    \item{}{
      \code{bpvec(X, FUN, ..., AGGREGATE=c, BPPARAM=bpparam())}
    }
    \item{}{
      \code{bpiterate(ITER, FUN, ..., BPPARAM=bpparam())}
    }
    \item{}{
      \code{bpaggregate(x, data, FUN, ..., BPPARAM=bpparam())}
    }
  }

}

\section{Methods: Other}{

  In the code below \code{x} is a \code{SnowParam} object.
  \describe{
    \item{}{
      \code{show(x)}:
      Displays the \code{SnowParam} object. 
    }
    \item{}{
      \code{bpok(x)}:
      Returns a \code{logical()} vector: FALSE for any jobs that resulted in
      an error. \code{x} is the result list output by a \code{BiocParallel}
      function such as \code{bplapply} or \code{bpmapply}. 
    }
  }

}

\section{Coercion}{

  \describe{
    \item{}{
      \code{as(from, "SnowParam")}:
      Creates a \code{SnowParam} object from a \code{SOCKcluster} or
      \code{spawnedMPIcluster} object. Instances created in this way
      cannot be started or stopped.
    }
  }

}

\author{Martin Morgan and Valerie Obenchain.}

\seealso{

  \itemize{
    \item \code{register} for registering parameter classes for use in 
          parallel evaluation.

    \item \code{\link{MulticoreParam}} for computing in shared memory

    \item \code{\link{BatchJobsParam}} for computing with cluster schedulers

    \item \code{\link{DoparParam}} for computing with foreach 

    \item \code{\link{SerialParam}} for non-parallel evaluation 
  }

}

\examples{

## -----------------------------------------------------------------------
## Job configuration:
## -----------------------------------------------------------------------

## SnowParam supports distributed memory computing. The object fields
## control the division of tasks, error handling, logging and 
## result format.
bpparam <- SnowParam()
bpparam

## Fields are modified with accessors of the same name:
bplog(bpparam) <- TRUE
bpresultdir(bpparam) <- "/myResults/"
bpparam

## -----------------------------------------------------------------------
## Logging:
## -----------------------------------------------------------------------

## When 'log == TRUE' the workers use a custom script (in BiocParallel) 
## that enables logging and access to other job statistics. Log messages 
## are returned as each job completes rather than waiting for all to finish.

## In 'fun', a value of 'x = 1' will throw a warning, 'x = 2' is ok
## and 'x = 3' throws an error. Because 'x = 1' sleeps, the warning
## should return after the error.

X <- 1:3 
fun <- function(x) {
    if (x == 1) {
        Sys.sleep(2)
        if (TRUE & c(TRUE, TRUE))  ## warning
            x 
    } else if (x == 2) { 
        x                          ## ok
    } else if (x == 3) { 
        sqrt("FOO")                ## error
    }
}

## By default logging is off. Turn it on with the bplog()<- setter
## or by specifying 'log = TRUE' in the constructor.
bpparam <- SnowParam(3, log = TRUE)
bplapply(X, fun, BPPARAM=bpparam)

## When a 'logdir' location is given the messages are redirected to a file:
bplogdir(bpparam) <- tempdir()
bplapply(X, fun, BPPARAM = bpparam)
list.files(bplogdir(bpparam))

## -----------------------------------------------------------------------
## Managing results:
## -----------------------------------------------------------------------

## By default results are returned as a list. When 'resultdir' is given
## files are saved in the directory specified by job, e.g., 'TASK1.Rda', 
## 'TASK2.Rda', etc.
bpparam <- SnowParam(2, resultdir = tempdir())
bplapply(X, fun, BPPARAM = bpparam)
list.files(bpresultdir(bpparam))

## -----------------------------------------------------------------------
## Error handling:
## -----------------------------------------------------------------------

## When 'stop.on.error' is TRUE, the process returns as soon as an error 
## is thrown. 
bpparam <- SnowParam(2, stop.on.error = TRUE)
bplapply(list(1, "two", 3, 4), sqrt, BPPARAM = bpparam)

## When 'stop.on.error' is FALSE, behavior is dictated by 'catch.errors'.
## By default 'catch.errors' is TRUE and will try all computations,
## successful or not.
bpparam <- SnowParam(2, stop.on.error = FALSE)
res <- bplapply(list(1, "two", 3, 4), sqrt, BPPARAM = bpparam)
res

## Calling bpok() on the result list returns TRUE for elements with no error.
bpok(res)

}

\keyword{classes}
\keyword{methods}
