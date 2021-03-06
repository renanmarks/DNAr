% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/analysis.R
\name{analyze_behavior}
\alias{analyze_behavior}
\title{This function returns the concentration derivative of each species}
\usage{
analyze_behavior(species, ci, reactions, ki, time_points = NULL,
  behavior = NULL)
}
\arguments{
\item{time_points}{A vector of indexes (representing multiple points in
time) used for access lines of \code{behavior}.}

\item{behavior}{The data returned by \code{\link{react}()}.}
}
\value{
A data frame with the derivatives. To access the derivative
of a species \code{'A'}, you just have to access \code{df['A']}.
}
\description{
This function can be used for study what is impacting each species and
how much. this is useful to analyse medium size (dozens of reactions) CRNs.
all parameters follows the parameters of \code{\link{react}()}, except
the optional \code{time_point} and \code{behavior}. If a \code{time_point} is passed,
a \code{behavior} must be passed as well. If both parameters are set,
this functions returns the concentration of each species
at a specific point in time within the derivative.
}
