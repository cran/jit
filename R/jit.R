# jit.R
#
# This makes sure that "is.ra", "jit", and "nojit" are defined.
#
# In the R environment, we define all these from scratch.
#
# In the Ra environment, "jit" is already defined internally.
# Also "nojit" is defined internally but needs some padding
# around it, which we add here.

is.ra <- FALSE

# Define a dummy jit function.
# We define jit's return value once and for all here, so calls 
# to jit are as efficient as possible (no mallocs needed).

result <- c(0L, 0L, 0L)
names(result) <- c("jit", "trace", "callers.jit")

jit <- function(jit = NA, trace = 0) {
    if(is.na(jit))      # default arg?
        result          # show result
    else
        invisible(result)
}

nojit <- function(sym = NULL) {
    sym                 # evaluate to check that sym exists
    result <- NULL
    # use substitute else do_nojit gets the already evaluated sym
    if(is.ra)
        result <- .Internal(nojit(substitute(sym)))
    if(is.null(sym))    # default arg?
        invisible(result)
    else
        result          # show nojit symbols
}

.onLoad <- function(lib, pkg) {
    is.ra <<- length(grep(" Ra ", R.version.string)) != 0
    if(is.ra) {
        # we are running standard Ra, so delete the jit defined
        # above (leaving the internally defined jit in place)
        rm(jit, inherits=TRUE)
    }
}
