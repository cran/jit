\name{jit}
\alias{jit}
\title{Just-in-time compilation}
\description{
  Enable just-in-time (JIT) compilation of a block of R code.
  Arithmetic in loops in a JIT block is generally faster.

  This function is only useful under Ra.
  It has no effect under standard R.
  See \url{http://www.milbo.users.sonic.net/ra}.

  This help page is for Ra 1.3.0 and higher.
}
\usage{
  jit(jit = NA, trace = 0)
}
\arguments{
  \item{jit}{
    \strong{NA} Make no changes but return the current JIT state (default)

    \strong{0}  End JIT block.
        Using \code{jit(0)} is usually unnecessary because an implicit \code{jit(0)} is
        performed when the function returns.

    \strong{1}  Start JIT block.

    \strong{2}  Start JIT block with extra optimization of nested loops.
                Fast but potentially dangerous, see below.

    \strong{3}  Start JIT block with sanity checks.
                Very slow, mainly for development of the jitter code.\cr\cr

  }
  \item{trace}{
    \strong{0} Silent (default).

    \strong{1} Show which expressions are compiled to JIT code.

    \strong{2} Show compilation details.

    \strong{3} Show code generation details.  With \code{jit=3} also show code execution.
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
          and vectors (but not matrices).
          Here "scalar" means a vector of \link{length} one.
          Both arguments of a binary operator must have the same
          length, or one of them must have length 1 (general R recycling
          is not jitted).

        \item Assignment to scalars or vectors: \code{x <- y}

        \item \link[=Extract]{Subscripted} vectors: \code{x[i] <- y[j]}.
         Multiple subscripts \code{x[i,j]} are not jitted
         on the lhs of assignments.

        \item \link{Control} constructs such as
          \link[=Control]{if} and \link[=Control]{for}
          when the condition is
          \link{logical}, \link{integer}, or \link{double}.

        \item The following (one argument) functions when the argument is
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
        \link{log2}
        \link{log10}
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
    Functions called from the JIT block are not jitted.
    For example, the \code{for} in the first line of code below is not
    compiled because it is called from within \code{system.time}.
\preformatted{
    jit(1); system.time({ for(i in 1:100) x<-x+i })   # is not jitted
    system.time({ jit(1); for(i in 1:100) x<-x+i })   # is jitted
}
    Use \code{trace>=1} to see what was jitted
    (and possibly modify your code to enable more jitting).
    Code in a JIT block that is not actually jitted will run as
    normal R code and coexist happily with jitted code.

\strong{Summary of the differences between standard R and jitted code}

    The semantics of jitted code differ from standard R where retaining
    compatibility would have made the jitted code substantially slower.
    Bear in mind that not everything in a JIT block is necessarily jitted.
    Non-jitted code in a JIT block retains R's usual semantics.

    The short version of the next few sections is:
\itemize{
    \item You will get an error message if you change the type or length
          of a jitted variable.  There are a few other semantic restrictions.
    \item Arithmetic in jitted code is similar to C.
    \item Avoid NAs in jitted code (NaNs are ok).
}
\strong{Differences between standard R and jitted code}

    The JIT compiler will not allow you to change the length or type of a jitted variable.
    (For this reason, the "L" suffix to define an integer constant \code{123L} is
    useful in JIT blocks, although seldom used in standard R code.)
    Here "type" means the type returned by \link{typeof}, such as
    \code{logical}, \code{integer}, or \code{double}.

    The JIT compiler will not allow you to use functions like
    \link{attach} in a JIT block or in functions called from the JIT block.
    The idea is to keep the environment stable so jitted code can be efficient.

    \link[=NA]{NAs} of type \link{integer} and \link{logical} are not handled
    in jitted code.
    \link[=double]{Double} NAs in arithmetic expressions may be converted to NaNs
    on some architectures.
    The results of comparison to \link{NaN} differ between standard R and jitted code.
    The next section gives details.

    Integer arithmetic overflows are detected in standard R but not in jitted code

    Most attributes of jitted variables are dropped.

    An out-of-range index in a jitted expression will cause an error message
    (the \code{check.bounds} \link{options} setting is ignored):
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
    provided by the hardware is defined to be the double NA.
    The hardware therefore makes no distinction between double NAs and other NaNs.
    Standard R evaluation has some software to handle double NAs
    over and above the hardware
    (mostly in type conversions, which don't get jitted anyway);
    jitted code has no such software.
    Thus in jitted code, double NAs behave identically to NaNs.

    On some architectures,
    the result of an jitted expression including a double NA may be NaN, not NA
    i.e. double NAs may be propagated as NaNs.

    \bold{Integer and logical NAs}:
    Integer and logical NAs
    are meaningless in jitted code, and will cause incorrect results if used.
    The following explains why.
    Integer and logical NAs are represented by \code{INT_MIN} internally in R,
    where \code{INT_MIN} is the minimum integer representable in a machine word
    (on a 32 bit machine, \code{INT_MIN} is about -2e9).
    The hardware does not know about integer and logical NAs.
    In standard R these are therefore handled in software;
    in jitted code they are treated like any other integer.
    Thus a logical or integer NA in jitted code is treated as
    an integer with the value \code{INT_MIN} (with a logical value of TRUE).

    Remember that a plain NA in your program text is treated
    as \emph{logical} by R.
    In the standard R code below, the software recognizes that the
    logical NA is a NA, and thus correctly converts it to a double NA
    (the conversion is necessary to add the NA to 1.2):

        \code{1.2 + NA   # evaluates to NA in standard R}

    In jitted code, the logical NA is not recognized as a NA ---
    it is treated as an integer with the value \code{INT_MIN} and is
    thus converted to a double with the value \code{INT_MIN}:

        \code{1.2 + NA   # evaluates to 1.2 + INT_MIN in jitted code}.

    Summarizing, avoid NAs in jitted code unless you are sure
    that your NA is a double.

    In jitted code, comparing anything to a NaN results in \code{FALSE},
    as per IEEE 754:

\preformatted{
                      standard R            jitted

        1.2 == NaN        NA                FALSE
        1.2 > NaN         NA                FALSE
        NaN == NaN        NA                FALSE (sic)
}

   Other discrepancies:
\preformatted{
                      standard R            jitted

        1L \%/\% 0L     integer NA        runtime error message
        1L \%\% 0L      integer NA        runtime error message
}
  These discrepancies are justified by the fact that integer NAs
  are meaningless in jitted code so it does not make sense to generate one.
  On the other hand, standard division "/" of an integer by zero evaluates
  to double \code{Inf} in both standard R and jitted code.

\strong{Optimizing nested loops with jit(2)}

  Use \code{jit(2)} for extra optimization of inner nested loops.
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
  To be optimized this way the entire inner loop body must be jittable and
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
        It is, however, ok to use \code{return} in the inner loop.
  \item There is no NAMED handling in the inner loop [TODO elaborate].
  \item Assigning to the inner loop variable causes incorrect results and
        an error message (which is issued only at the
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

% \strong{Note for package writers}
% 
% If your package benefits from \code{jit}, then
% we suggest that you simply make your package require \code{jit}
% (by putting \code{Depends:jit} in the \code{DESCRIPTION} file).
% People can then use standard R with your package ---
% calls to \code{jit()} will have no effect but will not cause warnings or errors ---
% but people who use Ra will get speedups.
% You could put a remark in your package documentation saying
% that speed will be improved using Ra instead of R.
% % You can also use \code{\link{is.ra}} to issue a warning if
% % you really want your users to use Ra instead of R.
}
\value{
    This function returns a three element integer vector.\cr

    \bold{Value under R}\cr\cr
    All elements are 0.\cr

    \bold{Value under Ra}\cr\cr
       \code{[1]} The value of the last specified \code{jit} argument to \code{jit()},
             so is \code{1}, \code{2}, or \code{3} if in a JIT block, else \code{0}.
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
    For more information on the jitter see \url{http://www.milbo.users.sonic.net/ra}\cr\cr
    \code{\link{nojit}}\cr
    \code{\link{is.ra}}\cr
    \code{\link[=compile]{enableJIT}} in the \code{\link[=compile]{compiler}} package is not related\cr
    \code{\link{jitter}} is not related
}
\examples{
foo <- function(N, jit.flag) {
    jit(jit.flag)
    x <- 0
    for (i in 1:N)
       x <- x + 1
    x
}
if(!is.ra)
    cat("\nExpect no speedup because you are running R, not Ra.\n")
N = 1e6
time.nojit <- system.time(foo(N, jit.flag=0))[1]
time.jit   <- system.time(foo(N, jit.flag=1))[1]
cat("Time ratio", time.nojit / time.jit, "\n")
jit(0)
}
\keyword{programming}
