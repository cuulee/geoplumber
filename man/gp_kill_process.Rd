% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{gp_kill_process}
\alias{gp_kill_process}
\title{Wrapper function to kill what is listening on a particular port.}
\usage{
gp_kill_process(port = 3000)
}
\arguments{
\item{port}{targted port to kill process for defaults to \code{3000}}
}
\description{
Detect sysytem and run command based on OS. This function supports
Linux, MacOS and Windows. There is no guarantee to kill the process.
}
\examples{
{
gp_kill_process()
}

}
