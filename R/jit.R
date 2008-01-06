# jit.R

# Define is.ra but only if it is not yet defined.

defined <- function(pat, env) 
    length(grep(pat, ls(envir=env))) != 0

if (!defined("^is.ra$", .GlobalEnv))
    is.ra <- (length(grep(" Ra", R.version.string, ignore.case = TRUE)) != 0)

# remove previous def of nojit, if any, for a quiet load

if(length(grep("^nojit$", ls(envir=.GlobalEnv))))
    try(rm("nojit", envir=.GlobalEnv))

nojit <- function(sym = NULL)
{
    # use substitute else do_nojit gets the already evaluated sym

    result <- NULL

    if (is.ra)
        result <- .Internal(nojit(substitute(sym)))

    if (is.null(sym)) 		# default arg?
	result			# show nojit symbols
    else
	invisible(result)
}

if (!is.ra) { 
    # Standard R, so must define dummy jit function
    # (under Ra will use the do_jit defined in jit.c).

    if (defined("jit", env=.GlobalEnv))
	try(rm("jit", envir=.GlobalEnv))

    # define return value once here, for efficiency in jit()

    result <- c(0L, 0L, 0L)

    jit <- function(jit = NA, trace = 0)
    {
	if (is.na(jit))	# default arg?
	    result	# show result
	else
	    invisible(result)
    }
}
