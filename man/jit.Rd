\name{jit}
\alias{jit}
\title{Just-in-time compilation}
\description{
  Enable just-in-time (JIT) compilation of a block of R code.
  Loops in a JIT block are generally much faster.

  This function is only useful under Ra.
  It has no effect under standard R.
  See \url{http://www.milbo.users.sonic.net/ra/index.html}.

  This help page is for Ra 1.0.6 and higher.
}
\usage{
  jit(jit = NA, trace = 0)
}
\arguments{
  \item{jit}{
    \strong{NA} make no changes but return the current JIT state (default)

    \strong{0}  end JIT block ---
        using \code{jit(0)} is often unnecessary because an implicit \code{jit(0)} is
        performed when the function returns

    \strong{1}  start JIT block

    \strong{2}  start JIT block with extra optimization of inner loops (fast but
                potentially dangerous, see below)
  }
  \item{trace}{
    \strong{0} silent (default)

    \strong{1} show which expressions are compiled to JIT code

    \strong{2} show compilation details

    \strong{3} show code generation details
  }
}
\details{

\strong{Nomenclature}

    A \emph{JIT block} is the R code between \code{jit(1)} and
    \code{jit(0)} or the end of the function.

    \emph{Jitted code} is R code that has been compiled by the
    just-in-time compiler (to a form where it will execute more
    quickly).
    Not all code in a JIT block is necessarily jitted.

    A \emph{jitted variable} is a variable used in jitted code.

\strong{What gets jitted?}

    The following operations are jitted, but only if they
    are in a \link{for}/\link{while}/\link{repeat}
    loop in a JIT block:

    \itemize{
        \item \link{Arithmetic} and \link[=Comparison]{comparison} operations on
          \link{logical}, \link{integer}, and \link{double} scalars
          and vectors.
          Here "scalar" means a vector of \link{length} one.
          Both arguments of a binary operator must have the same
          length, or one of them must have length 1 (general R recycling
          is not jitted).

        \item Assignment to scalars or vectors: \code{x <- y}

        \item \link[=Extract]{Subscripted} vectors with a positive integer 
         or real scalar subscript: \code{x[i] <- y[j]}

        \item \link{Control} constructs such as
          \link[=Control]{if} and \link[=Control]{for}
          when the condition is
          \link{logical}, \link{integer}, or \link{double}.

        \item The following functions when the argument is
          \link{logical}, \link{integer}, or \link{double}:
        \link{abs}
        \link{acos}
        \link{acosh}
        \link{asin}
        \link{asinh}
        \link{atanh}
        \link{ceiling}
        \link{cos}
        \link{cosh}
        \link{digamma}
        \link{exp}
        \link{expm1}
        \link{floor}
        \link{gamma}
        \link{gammaCody}
        \link{lgamma}
        \link{log}
        \link{log1p}
        \link{sin}
        \link{sign}
        \link{sinh}
        \link{sqrt}
        \link{tan}
        \link{tanh}
        \link{trigamma}
        \link{trunc}.
       Some of these functions can take more than one argument;
       they are jitted only if given one argument.
    }

    Use \code{trace>=1} to see what was jitted
    (and possibly modify your code to enable more jitting).
    Code in a JIT block that is not actually jitted will run as
    normal R code and coexist happily with jitted code.
    Functions called from the JIT block are not jitted.

\strong{Summary of the differences between standard R and jitted code}

    The semantics of jitted code differ from standard R where retaining
    compatibility would have made the jitted code substantially slower.
    Bear in mind that not everything in a JIT block is necessarily jitted.
    Non-jitted code in a JIT block retains R's usual semantics.

    The short version of the next few sections is:
\itemize{
    \item you will get an error message if you change the type or length 
          of a jitted variable.  There are a few other semantic restrictions.
    \item arithmetic in jitted code is similar to C
    \item don't use NAs in jitted code
}
\strong{Differences between standard R and jitted code}

    The JIT compiler will not allow you to change the length or type of a jitted variable.
    (For this reason, the "L" suffix to define an integer constant is useful in JIT blocks,
    although seldom used in standard R code.)
    Here "type" means the type returned by \link{typeof}.

    The JIT compiler will not allow you to use functions like
    \link{attach} in a JIT block or in functions called from the JIT block.
    The idea is to keep the environment stable so jitted code can be efficient.

    \link[=NA]{NAs} of type \link{integer} and \link{logical} are not handled 
    in jitted code --- the next section gives details.

    The results of comparison to \link{NaN} differ between standard R and jitted code
     --- the next section gives details.

    Integer arithmetic overflows are detected in standard R but not in jitted code

    Most attributes of jitted variables are dropped.

    An out-of-range index in a jitted expression will cause an error message
    (the \link{options} \code{check.bounds} setting is ignored):
\preformatted{
x <- 1; x[3]   # NA in standard R but "Error: out-of-range index" when jitted
}
    The value of a loop is the last evaluated loop body in standard R,
    but NULL in jitted code:
\preformatted{
x <- for (i in 1:3) 99  # x is set to 99 in standard R but NULL when jitting
}

\strong{NaNs and NAs}

    \bold{NaNs}: In jitted code \link[=NaN]{NaNs} (always \link{double})
    are handled directly by the machine hardware,
    as is usually the case in standard R.
    (We assume IEEE 754 hardware \url{http://en.wikipedia.org/wiki/IEEE_754}.)
    The hardware knows about double NaNs:
    where necessary it will generate them (zero divided by zero is NaN)
    and propagate them (NaN + 123 is  NaN). 

    \bold{Double NAs}: In R, one of the many possible values of NaN
    provided by the hardware is defined to be the \link{double} \link{NA}.
    The hardware therefore makes no distinction between double NAs and other NaNs.
    Standard R evaluation has some software to handle double NAs
    over and above the hardware 
    (mostly in type conversions, which don't get jitted anyway);
    jitted code has no such software.
    Thus in jitted code, double NAs behave identically to NaNs.

    \bold{Integer and logical NAs}:
    Integer and logical NAs 
    are meaningless in jitted code, and will cause incorect results if used.
    Integer and logical NAs are represented by \code{INT_MIN} internally in R.
    Here \code{INT_MIN} is the minimum integer representable in a machine word.
    (On a 32 bit machine, \code{INT_MIN} is about -2e9.)
    The hardware does not know about integer and logical NAs.
    In standard R these are therefore handled in software;
    in jitted code they are treated like any other integer.
    Thus a \link{logical} or \link{integer}
    \link{NA} in jitted code is treated as 
    an integer with the value \code{INT_MIN} (with a logical value of TRUE).

    Remember that a plain NA in your program text is treated
    as \emph{logical} by R and thus as \code{INT_MIN} in jitted code.
    In the standard R code below, the logical NA is
    converted to a double NA (because 1.2 is double, making the
    whole expression double):

        \code{1.2 + NA   # evaluates to NA in standard R}

    In jitted code, the NA is treated by the machine
    hardware as an integer with the value \code{INT_MIN} and is
    thus converted to a double with the value \code{INT_MIN}:

        \code{1.2 + NA   # evaluates to 1.2 + INT_MIN in jitted code}.

    Summarizing, avoid NAs in jitted code unless you are sure
    that your NA is a \link{double}.

    In jitted code, comparing anything to a NaN results in \code{FALSE},
    as per IEEE 754:

\preformatted{
                      standard R            jitted

        1.2 == NaN        NA                FALSE
        1.2 > NaN         NA                FALSE
        NaN == NaN        NA                FALSE (sic)
}

   Other discrepancies (these were tested on a Windows XP Pentium D system):
\preformatted{
                      standard R            jitted

        0 ^ NaN       Inf (why?)              NaN
        1L \%/\% 0L     integer NA        runtime error message
        1L \%\% 0L      integer NA        runtime error message
}
  The last two are justified by the fact that \link{integer} NAs
  are meaningless in jitted code so it does not make sense to generate one.
  On the other hand, standard division "/" of an integer by zero evaluates to
  double \code{Inf} in both standard R and jitted code.

\strong{Optimizing nested loops with jit(2)}
 
  Use \code{jit(2)} instead of \code{jit(1)} for extra optimization
  of inner nested loops.  
  In the example below the inner \code{j} loop will
  undergo this optimization:
\preformatted{
    jit(2)
    for (i in 1:n) {   # same as jit(1) because is outermost loop
	...
	for (j in 1:m) # extra optimization with jit(2), 1:m must not change
	    ...        # any further loops in here also optimized with jit(2)
	...
    }
}
  To be optimized this way the entire inner loop body must be jitted and
  the loop sequence (\code{1:m} above) must have integer type.

  There are some \strong{important conditions} when using \code{jit(2)}.
  The danger is that R will usually not warn you
  if your code doesn't meet a condition --- you will just get wrong results.
  Because of this danger, \code{jit(2)} is considered experimental at present.
  The conditions are:
   \itemize{
   \item The inner loop sequence 
   (\code{1:m} in the example above) is calculated just once and 
  thereafter assumed constant for the entire JIT block.
  Thus the example code above will give incorrect results without warning
  if \code{m} changes between the curly braces (which would require
  a recalculation of \code{1:m}).
  It is fine to change \code{n} since this affects only the outer loop.
  \item Do not use \code{break} or \code{next} in the inner loop (they
        will incorrectly break to the outer loop, but please don't rely on this).
  \item There is no NAMED handling in the inner loop [RA\_TODO elaborate].
  \item Assigning to the inner loop variable causes incorrect results and
        and an error message (which is issued only at the
        end of the loop):
}
\preformatted{
	jit(2)
	for (i in 1:3)
	   for (j in 1:3)
	       j = 9L     # error msg: assignment to loop variable "j"
}

\strong{Limits of the current implementation}

    You can JIT only one function at any time.
    A call to \code{jit} in a function that is called from a JIT block
    is ignored with a warning message.

    Jitted code uses more memory than standard R.
    This is because jitted code does not release the temporary buffers used to
    evaluate expressions until the end of the JIT block.
    Standard R allocates and releases temporary buffers as it
    evaluates each expression.

    More types of expression will be jitted in future releases.

    Thorough testing of the jitter is still in progress.
}
\value{
    A three element integer vector.\cr

    \bold{Under R}\cr\cr
    All elements are 0.\cr

    \bold{Under Ra}\cr\cr
       \code{[1]} The value of the last specified \code{jit} argument to \code{jit()},
             so is \code{1} or \code{2} if in a JIT block, else \code{0}.
             Is \code{0} in functions called from the JIT block.\cr\cr
       \code{[2]} The value of the last specified \code{trace} argument to \code{jit()}.
             Is \code{0} in functions called from the JIT block.\cr\cr
       \code{[3]} The value of the last specified \code{jit} argument to \code{jit()}.
             Retains its value in functions called from the JIT block.\cr

    Be careful when using \code{jit()} as an argument to a function.  It will be evaluated
    as if called from that function.  Example:
\preformatted{
    jit(1)
    jit()[1]             # is 1
    print(jit()[1])      # prints 0, because jit() is called from print
    jit.flag <- jit()[1]
    print(jit.flag)      # prints 1
    }
}
\seealso{
    For more information on the jitter see \url{http://www.milbo.users.sonic.net/ra/index.html}\cr
    \code{\link{nojit}}\cr
    \code{\link{is.ra}}\cr
    \code{\link{jitter}} is not related
}
\examples{
foo <- function(N) {
    jit(jit.flag)
    x <- 0
    for (i in 1:N)
       x <- x + 1
    x
}
N = 3e5
jit.flag <- 0; time.nojit <- system.time(foo(N))[1]
jit.flag <- 1; time.jit   <- system.time(foo(N))[1]
cat("Time ratio", time.jit / time.nojit, "\n")
jit(0)
}
\keyword{programming}
