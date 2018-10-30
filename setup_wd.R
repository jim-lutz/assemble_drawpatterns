# setup_wd.R
# Jim Lutz
# "Tue Nov 21 07:33:16 2017"

# setup  working directories
# use this for scripts 
wd <- getwd()

wd_data    <- paste(wd,"/data/",sep="")      # use this for interim data files
wd_charts  <-paste(wd,"/charts/",sep="")     # use this for charts, ggsave puts in /

