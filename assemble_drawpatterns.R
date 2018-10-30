# assemble_drawpatterns.R
# script to build the complete draw pattern for CBECC_Res 
# contains all the draws for all days of the year for all number of bedrooms
# revised from /home/jiml/HotWaterResearch/projects/How Low/draw_patterns/make_total_drawpattern.R
# reads /home/jiml/HotWaterResearch/projects/How Low/draw_patterns/data/DT_total_drawpatterns.Rdata
# saves to drawpattern_{1:5}bed.csv

# fields are:
#   datetime      ymd_hms as POSIXct in tz "America/Los_Angeles"
#   yday          1-365
#   month         "Jan" "Feb", etc.
#   mday          1-31
#   start         "hh:mm:ss" as character
#   enduse        Bath	ClothesWasher	Dishwasher	Faucet	Shower
#   duration	    seconds
#   mxedFlow	    GPM
# Jim Lutz  "Tue Oct 30 11:02:08 2018"

# set packages & etc
source("setup.R")

# set up paths to working directories
source("setup_wd.R")

#  load DT_total_drawpatterns.Rdata
load( file = "/home/jiml/HotWaterResearch/projects/How Low/draw_patterns/data/DT_total_drawpatterns.Rdata")

tables()

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
#DT_total_drawpatterns[ , Start_Time := paste(strftime(ymd(date),"%m/%d/%Y"),start)]
DT_total_drawpatterns[ , Start_Time := paste(date,start)]
DT_total_drawpatterns[ , Start_Time := ymd_hms(Start_Time, tz="America/Los_Angeles")]
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

# list number of days by bedrooms
DT_total_drawpatterns[ , list(ndays=length(unique(date))), 
                       by=c('bedrooms')]
#    bedrooms ndays
# 1:        1   365
# 2:        2   365
# 3:        3   365
# 4:        4   365
# 5:        5   365

# list number of days and ave draws per day by bedrooms
DT_total_drawpatterns[ , list(ndays=length(unique(date)),
                              ndraws = ave), 
                       by=c('bedrooms')]






# save the DT_total_drawpatterns data as a csv file
write.csv(DT_total_drawpatterns, 
          file= paste0(wd_data,"DT_total_drawpatterns.csv"), 
          row.names = FALSE)

# some brief data checks
setorder(DT_total_drawpatterns, DHWProfile, DHWDAYUSE, date, start)

DT_total_drawpatterns[ , list(first = min(date),
                              last  = max(date)),
                       by=c('DHWProfile', 'enduse')]
# seems OK

# summary by # bedroooms, date, WEH, # people, # draws, total (mixed) volume, 
# sum draws by enduse
names(DT_total_drawpatterns)

# build the summary by day
DT_daily_summary <-
  DT_total_drawpatterns[,list(date      = unique(date),
                              wday      = unique(wday),
                              DHWDAYUSE = unique(DHWDAYUSE),
                              bedrooms  = unique(bedrooms),
                              people    = unique(people),
                              totvol    = sum(mixedFlow*duration/60),
                              ndraw     = length(start)
                              ),
                        by=c('DHWProfile', 'yday')][order(DHWProfile,yday)]

# count number of enduses by DHWProfile & day
DT_total_enduses <- 
  DT_total_drawpatterns[,list(ndraws = length(start)), 
                        by=c('DHWProfile', 'yday', 'enduse')
                        ][order(DHWProfile,yday)]

# rearrange DT_total_enduses to wide
DT_daily_enduses <-
  dcast(DT_total_enduses, 
        DHWProfile + yday ~ enduse, value.var = 'ndraws', fill = 0)

# combine daily summary and daily enduses
DT_daily <- 
  merge(DT_daily_summary, DT_daily_enduses, by=c('DHWProfile', 'yday'))

# reorder the columns
setcolorder(DT_daily, c('DHWProfile', 'yday', 'date', 'wday', 'DHWDAYUSE', 'bedrooms', 'people',
                        'totvol', 'ndraw', 
                        'Faucet', 'Shower', 'ClothesWasher', 'Dishwasher', 'Bath'))

# save the DT_daily data as a csv file
write.csv(DT_daily, file= paste0(wd_data,"DT_daily.csv"), row.names = FALSE)

# separate files by number of bedrooms
for(b in 1:5) {
  write.csv(DT_daily[bedrooms==b,], file= paste0(wd_data,"DT_daily",b,".csv"), row.names = FALSE)
  }

# save the DT_daily data as an .Rdata file
save(DT_daily, file = paste0(wd_data,"DT_daily.Rdata"))

# scatter plot of volume vs number of draws per DHWDAYUSE
ggplot(data=DT_daily[bedrooms==3]) +
  geom_jitter(aes(x=totvol, y= ndraw, size=people), 
             width = 5, height = 5, alpha = 0.2 ) +
  ggtitle( "Daily Draw Patterns" ) +
  theme(plot.title = element_text(hjust = 0.5)) + # to center the title
  scale_x_continuous(name = "total mixed water drawn (gallons/day)") +
  scale_y_continuous(name = "total number of draws per day") +
  labs(caption="from CBECC-Res19") #+ 
  # guides(size=FALSE)


