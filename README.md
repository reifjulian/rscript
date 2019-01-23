# RSCRIPT: call an R script from Stata.

- Current version: `1.0 22jan2019`
- Jump to: [`updates`](#recent-updates) [`install`](#install) [`description`](#description) [`authors`](#authors)

-----------

## Updates:

* **January 22, 2019**
  - Added ```force``` option

## Install:

Type `which rscript` at the Stata prompt to determine which version you have installed. To install the most recent version of `rscript`, copy/paste the following line of code:

```
net install rscript, from("https://raw.githubusercontent.com/reifjulian/rscript/master") replace
```

## Description: 

`rscript` is a [Stata](http://www.stata.com) command that runs an R script and displays the output in the Stata console.

For more details, see the Stata help file included in this package.

## Authors:

[David Molitor](http://www.davidmolitor.com)
<br>University of Illinois
<br>dmolitor@illinois.edu

[Julian Reif](http://www.julianreif.com)
<br>University of Illinois
<br>jreif@illinois.edu
