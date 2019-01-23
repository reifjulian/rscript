{smcl}
{hi:help rscript}
{hline}
{title:Title}

{p 4 4 2}{cmd:rscript} {hline 2} Call an R script from Stata.


{title:Syntax}

{p 8 14 2}{cmd:rscript} {cmd:using} {it:filename.R}, {cmd:rpath(}{it:pathname}{cmd:)} [{cmd:args(}{it:{it:filename}}{cmd:) {cmd:force}}]

{p 4 4 2}where

{p 8 14 2}{it: pathname} specifies the location of the R executable and

{p 8 14 2}{it: stringlist} is a list of quoted strings.


{title:Description}

{p 4 4 2}{cmd:rscript} calls the R script {it:filename.R} from Stata. It displays the R output (and errors, if applicable) in the Stata console.


{title:Options}

{p 4 8 2}
{cmd:rpath(}{it:pathname}{cmd:)} specifies the location of the R executable (e.g., Rscript.exe).


{p 4 8 2}
{cmd:args(}{it:filename}{cmd:)} specifies optional arguments to be passed to R.


{p 4 8 2}
{cmd:force} instructs {cmd:rscript} to not break when {it:filename.R} generates an error during execution.


{title:Notes}

{p 4 8 2}{cmd:rscript} has been tested on Windows and on the Unix tcsh shell.


{title:Examples}

{p 4 4 2}1.  Call an R script and pass it the name of an input file.

{col 8}{cmd:. {stata rscript using example_1.R, rpath("`rscript_exe'") args("arg1" "arg2")}}


{title:Authors}

{p 4 4 2}David Molitor, University of Illinois

{p 4 4 2}dmolitor@illinois.edu


{p 4 4 2}Julian Reif, University of Illinois

{p 4 4 2}jreif@illinois.edu


{title:Also see}

{p 4 4 2}
{help rsource:rsource} (if installed)