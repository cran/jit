# test.jit.R
# This just does a basic test to check that the jit package ported 
# without problems.  Much more complete tests are included in the 
# Ra source distribution. The complete tests are not included here
# because they give different output for R and Ra.

library(jit)
foo <- function(jit.flag)
{
    jit(jit.flag)
    N <- 3e5
    x <- double(N)
    for(i in 1:N)
        x[i] <- i + 1
    x
}
time.nojit <- system.time(foo.nojit <- foo(0))[1];
time.jit   <- system.time(foo.jit   <- foo(1))[1];
stopifnot(identical(foo.nojit, foo.jit))
stopifnot(!is.ra || time.nojit / time.jit > .3)
