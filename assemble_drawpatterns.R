# make_total_drawpattern.R
# script to build the complete draw pattern for CBECC_Res 
# contains all the draws for all days of the year for all number of bedrooms
# fields are:
#   DHWProfile    "DHW1BR"
#   DHWDAYUSE     "3H1"
#   bedrooms      1-5
#   people        1-6
#   datetime      ymd_hms as POSIXct in tz "America/Los_Angeles"
#   yday          1-365
#   month         "Jan" "Feb", etc.
#   mday          1-31
#   start         "hh:mm:ss" as character
#   enduse        Bath	ClothesWasher	Dishwasher	Faucet	Shower
#   duration	    seconds
#   mxedFlow	    GPM
#   hotFlow       GPM
#   coldFlow      GPM 
# saves DT_total_drawpattern to .Rdata and .csv files
# Jim Lutz  "Fri Aug  3 08:59:12 2018"

# set packages & etc
source("setup.R")

# set up paths to working directories
source("setup_wd.R")

#  load DT_DHWProfiles.Rdata
load( file = paste0(wd_data,"DT_DHWProfiles.Rdata"))

DT_DHWProfiles
str(DT_DHWProfiles)
# Classes ‘data.table’ and 'data.frame':	365 obs. of  6 variables:
# $ day   : int  1 2 3 4 5 6 7 8 9 10 ...
# $ DHW1BR: chr  "1H1" "1D3" "3E2" "1E1" ...
# $ DHW2BR: chr  "1H1" "3D3" "1E2" "4E1" ...
# $ DHW3BR: chr  "3H1" "1D3" "2E2" "4E1" ...
# $ DHW4BR: chr  "3H1" "6D3" "1E2" "2E1" ...
# $ DHW5BR: chr  "4H1" "2D3" "5E2" "3E1" ...
# - attr(*, ".internal.selfref")=<externalptr> 
#   - attr(*, "index")= atomic  
# ..- attr(*, "__day")= int 

# change into a long dataset
DT_DHWProfiles.long <-
melt.data.table( data = DT_DHWProfiles, 
                 id.vars = "day", 
                 variable.name = "DHWProfile",
                 value.name = "DHWDAYUSE")

# extract number of bedrooms 
DT_DHWProfiles.long[ , bedrooms := str_extract(DHWProfile, "[1-5]" ) ]

# extract number of people 
DT_DHWProfiles.long[ , people := str_extract_all(DHWDAYUSE, "[1-6]", simplify = TRUE)[1:length(DHWDAYUSE),1] ]

# change name of day to yday
setnames(DT_DHWProfiles.long, old = c("day"), new = c("yday"))

#  load DT_DHWUSEs.Rdata
load( file = paste0(wd_data,"DT_DHWUSEs.Rdata"))

DT_DHWUSEs

# merge DT_DHWProfiles.long and DT_DHWUSEs into one long draw pattern
DT_total_drawpatterns <-
merge(DT_DHWProfiles.long, DT_DHWUSEs, by="DHWDAYUSE", allow.cartesian = TRUE)

# remove id & s
DT_total_drawpatterns[ , c("id", "s"):= NULL]

# duration in seconds
DT_total_drawpatterns[ , duration := duration * 60]

# make a data.table for 2009 of character dates & wday
# where row number is yday 
days_of_year <- seq(ymd("2009-01-01", tz="America/Los_Angeles"), 
                    ymd("2009-12-31", tz="America/Los_Angeles"), 
                    by="days")

DT_date2009 <- data.table(date=as.character(days_of_year, format="%F"),
                          wday=wday(days_of_year, label = TRUE, abbr = TRUE))
# add dates
DT_total_drawpatterns[ , c("date","wday") := list( DT_date2009[yday,date],
                                                   DT_date2009[yday,wday])
                       ]

# set order of columns
names(DT_total_drawpatterns)

#   DHWProfile    "DHW1BR"
#   DHWDAYUSE     "3H1"
#   bedrooms      1-5
#   people        1-6
#   yday          1-365
#   wday          Sun Mon Tue Wed Thu Fri Sat
#   date          "yyyy-mm-dd" in tz "America/Los_Angeles"
#   start         "hh:mm:ss" as character
#   enduse        Bath	ClothesWasher	Dishwasher	Faucet	Shower
#   duration	    seconds
#   mxedFlow	    GPM
#   hotFlow       GPM
#   coldFlow      GPM 

setcolorder(DT_total_drawpatterns,
            c("DHWProfile", "DHWDAYUSE", "bedrooms", "people", 
              "yday", "wday", "date", "start",
              "enduse", "duration", "mixedFlow", "hotFlow", "coldFlow")
            )

DT_total_drawpatterns

# save the DT_total_drawpatterns data as an .Rdata file
save(DT_total_drawpatterns, file = paste0(wd_data,"DT_total_drawpatterns.Rdata"))

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


