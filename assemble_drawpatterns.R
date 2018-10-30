# assemble_drawpatterns.R
# script to build the complete draw pattern for CBECC_Res 
# contains all the draws for all days of the year for all number of bedrooms
# revised from /home/jiml/HotWaterResearch/projects/How Low/draw_patterns/make_total_drawpattern.R
# reads /home/jiml/HotWaterResearch/projects/How Low/draw_patterns/data/DT_total_drawpatterns.Rdata
# saves to drawpattern_{1:5}bed.csv

# Jim Lutz  "Tue Oct 30 11:02:08 2018"

# set packages & etc
source("setup.R")

# set up paths to working directories
source("setup_wd.R")

#  load DT_total_drawpatterns.Rdata
load(file = "/home/jiml/HotWaterResearch/projects/How Low/draw_patterns/data/DT_total_drawpatterns.Rdata")

tables()
#                     NAME    NROW NCOL MB
# 1: DT_total_drawpatterns 114,573   13 10
#                                                  COLS       KEY
# 1: DHWProfile,DHWDAYUSE,bedrooms,people,yday,wday,... DHWDAYUSE
# Total: 10MB

DT_total_drawpatterns
str(DT_total_drawpatterns)
# Classes ‘data.table’ and 'data.frame':	114573 obs. of  13 variables:
# $ DHWProfile: Factor w/ 5 levels "DHW1BR","DHW2BR",..: 1 1 1 1 1 1 1 1 1 1 ...
# $ DHWDAYUSE : chr  "1D1" "1D1" "1D1" "1D1" ...
# $ bedrooms  : chr  "1" "1" "1" "1" ...
# $ people    : chr  "1" "1" "1" "1" ...
# $ yday      : int  13 13 13 13 13 13 13 13 13 13 ...
# $ wday      : Ord.factor w/ 7 levels "Sun"<"Mon"<"Tue"<..: 3 3 3 3 3 3 3 3 3 3 ...
# $ date      : chr  "2009-01-13" "2009-01-13" "2009-01-13" "2009-01-13" ...
# $ start     : chr  "01:18:00" "01:52:12" "02:05:24" "02:06:00" ...
# $ enduse    : chr  "Dishwasher" "Dishwasher" "Faucet" "Dishwasher" ...
# $ duration  : num  100 90 10 80 10 ...
# $ mixedFlow : num  1.145 1.014 0.317 1.179 0.226 ...
# $ hotFlow   : num  1.145 1.014 0.159 1.179 0.113 ...
# $ coldFlow  : num  0 0 0.159 0 0.113 ...
# - attr(*, ".internal.selfref")=<externalptr> 
#   - attr(*, "sorted")= chr "DHWDAYUSE

# sort by bedrooms, date, start
setkeyv(DT_total_drawpatterns, cols = c('bedrooms', 'date', 'start' ))

# add Start_Time as date & start in a POSIXct format
DT_total_drawpatterns[ , Start_Time := ymd_hms(paste(date,start), tz="America/Los_Angeles")]
# Warning message:
#   1 failed to parse. 

# which one?
DT_total_drawpatterns[is.na(Start_Time)]
#    DHWProfile DHWDAYUSE bedrooms people yday wday       date    start enduse duration
# 1:     DHW3BR       3E2        3      3   67  Sun 2009-03-08 02:42:36 Faucet    10.02
#    mixedFlow hotFlow coldFlow Start_Time
# 1:     0.272   0.136    0.136       <NA>
# probably a time change day, 
# ignore it for now, it's one small faucet draw

# list number of days, ndraws and volume per day by bedrooms
DT_total_drawpatterns[ , list(ndays   = length(unique(date)),
                              ndraws  = length(unique(Start_Time))/365,
                              ave.vol = sum(mixedFlow * duration/60)/365), 
                       by=c('bedrooms')]
#    bedrooms ndays   ndraws  ave.vol
# 1:        1   365 50.65479 51.90617
# 2:        2   365 56.81918 59.03678
# 3:        3   365 62.86027 67.13421
# 4:        4   365 63.00274 72.95947
# 5:        5   365 71.51781 83.49977

names(DT_total_drawpatterns)
#  [1] "DHWProfile" "DHWDAYUSE"  "bedrooms"   "people"     "yday"       "wday"      
#  [7] "date"       "start"      "enduse"     "duration"   "mixedFlow"  "hotFlow"   
# [13] "coldFlow"   "Start_Time"

# prune the data.table
DT_total_drawpatterns[ ,c("DHWProfile", "DHWDAYUSE", "people",
                          "hotFlow", "coldFlow") := NULL ]

# loop for each number of bedrooms
for( b in 1:5)  {
  # save the DT_total_drawpatterns data as a csv file
  write.csv(DT_total_drawpatterns[bedrooms==b], 
            file= paste0(wd_data,"drawpatterns_",b,"bed.csv"), 
            row.names = FALSE)
  }
