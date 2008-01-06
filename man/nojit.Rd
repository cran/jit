\name{nojit}
\alias{nojit}
\title{Inhibit just-in-time compilation of a variable}
\description{
  Inhibit just-in-time compilation of a variable.
}
\usage{
  nojit(sym = NULL)
}
\arguments{
  \item{sym}{ the variable
  }
}
\details{
The JIT compiler will not allow you to change the type or length
of a jitted variable.
Sometimes this can be a nuisance, and if so you can
use \code{nojit(variable)} to inhibit jitting of the specified variable.

Any error message (not necessarily issued by the jitter)
disables jitting and thus clears all \code{nojit} settings
i.e. if there is an error message you will have to re-\code{nojit} your variable.
}
\value{
A character vector containing the symbols marked as not jittable, if any,
else \code{NULL}.
}
\seealso{
  \code{\link{jit}}\cr
  \code{\link{is.ra}}
}
\examples{
\dontrun{
jit(1); x <- 0; y <- 0
nojit(x)         # allows use of "c" below which changes the length of x
for (i in 1:3) {
    x <- c(x,i)  # will not be jitted
    y <- y + 1   # will be jitted
}
nojit(0)
}
}
\keyword{programming}
