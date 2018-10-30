# setup.R
# make sure any needed packages are loaded
# Jim Lutz  "Tue Sep 12 15:46:11 2017"

# clean up leftovers before starting
# this is to prevent unintentionally using old data
l_obj=ls(all=TRUE)
l_obj = c(l_obj, "l_obj") # be sure to include l_obj
rm(list = l_obj)
# clear the plots
if(!is.null(dev.list())){
  dev.off(dev.list()["RStudioGD"])
}
# clear history
cat("", file = "nohistory")
loadhistory("nohistory")
# clear the console
cat("\014")

# only works if have internet access
update.packages(checkBuilt=TRUE)

sessionInfo() 
  # R version 3.4.3 (2017-11-30)
  # Platform: x86_64-pc-linux-gnu (64-bit)
  # Running under: Ubuntu 16.04.3 LTS

# work with plyr 
if(!require(plyr)){install.packages("plyr")}
library(plyr)

# work with data.tables
#https://github.com/Rdatatable/data.table/wiki
#https://www.datacamp.com/courses/data-analysis-the-data-table-way
if(!require(data.table)){install.packages("data.table")}
library(data.table)


# work with tidyverse
# http://tidyverse.org/
# needed libxml2-dev installed
if(!require(tidyverse)){install.packages("tidyverse")}
library(tidyverse)

# work with lubridate 
if(!require(lubridate)){install.packages("lubridate")}
library(lubridate)
# part of tidyverse but wasn't seeing it


# try readxl
if(!require(readxl)){install.packages("readxl")}
library(readxl)

# janitor for excel_numeric_to_date and other goodies
if(!require(janitor)){install.packages("janitor")}
library(janitor)

# work with stringr 
# if(!require(stringr)){install.packages("stringr")}
# library(stringr)
# part of tidyverse

# work with ggplot2
# if(!require(ggplot2)){install.packages("ggplot2")}
# library(ggplot2)
# part of tidyverse

# work with plotly
# https://plot.ly/r/getting-started/#getting-started-with-plotly-for-r
if(!require(plotly)){install.packages("plotly")}
library(plotly)

# required to export images from plotly
# if(!require(RSelenium)){install.packages("RSelenium")}
# library(RSelenium)

# environment variables for my plotly account.
Sys.setenv("plotly_username" = "jlutz")
Sys.setenv("plotly_api_key" = "8ynkq1jhd9f3auYGyO9O")

# change the default background for ggplot2 to white, not gray
theme_set( theme_bw() )



