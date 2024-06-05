# Script to convert consolidated source data into hubverse formatted data
# which will then be pushed to the model_output folder

# Note, this depends on parent script, 02-consolidate_original_raw_data
# specifically looking for an object `data` created by that script

library(lubridate)
library(data.table)
library(arrow)

rm(list=setdiff(ls(), "data"))
gc()

# Some Cleaning of src names

# KoT-GPthingy 2019-2020 - add a leading zero to epiweek
data[src=="EW2-KoT-GPthingy-2020-01-21.parquet", src:="EW02-KoT-GPthingy-2020-01-21.parquet"]

# EW46-ARETE-11-27-2017.parquet needs simple standardization of name
data[src=="EW46-ARETE-11-27-2017.parquet", src:="EW46-Arete-2017-11-27.parquet "]

# Kot-dev 2018-2019 - standardize names and infer date if not provided
data[src=="EW18-2019-ReichLab_KoT.parquet" & model=="KoT_dev", src:="EW18-KoT_dev-2019-05-14.parquet"]
data[src=="EW42-ReichLab_KoT_dev-2018-10-29.parquet" & model=="KoT_dev", src:="EW42-KoT_dev-2018-10-29.parquet"]
data[src=="EW43-2018-ReichLab_KoT_dev.parquet" & model=="KoT_dev", src:="EW43-KoT_dev-2018-11-07.parquet"]
data[src=="EW44-2018-ReichLab_KoT_dev.parquet" & model=="KoT_dev", src:="EW44-KoT_dev-2018-11-14.parquet"]
data[src=="EW52-2018-ReichLab_KoT_dev.parquet" & model=="KoT_dev", src:="EW52-KoT_dev-2019-01-08.parquet"]

# Kernel of Truth 2017-2018 - standardize names and infer date if not provided
data[src=="EW09-2018-ReichLab_KoT.parquet" & model=="Kernel of Truth", src:="EW09-Kernel of Truth-2018-03-12.parquet "]

# KoT 2018-2019 - standardize names and infer date if not provided
data[src=="EW18-2019-ReichLab_KoT.parquet" & model=="KoT", src:="EW18-Kernel of Truth-2019-05-14.parquet"]
data[src=="EW42-KoT_stable-2018-10-29.parquet" & model=="KoT", src:="EW42-KoT-2018-10-29.parquet"]
data[src=="EW43-2018-ReichLab_KoT_stable.parquet" & model=="KoT", src:="EW43-KoT-2018-11-07.parquet"]
data[src=="EW52-2018-ReichLab_KoT_stable.parquet" & model=="KoT", src:="EW52-KoT-2019-01-08.parquet"]

# BioFire 2018-2019 - standardize names and infer date if not provided
data[src=="EW42-BioFire-2018-10-29.parquet" & model=="BioFire FLI", src:="EW42-BioFire FLI-2018-10-29.parquet"]
data[src=="EW43-BioFire-2018-11-5.parquet" & model=="BioFire FLI", src:="EW43-BioFire FLI-2018-11-05.parquet"]

# LANL_Dante - standardize names and infer date if not provided
data[src=="EW43-2018-LANL_Dante.parquet" & model=="LANL-Dante",src:="EW43-LANL-Dante-2018-11-07.parquet"]

# LANL_DMBplus - standardize names and infer date if not provided
data[src=="EW43-2018-LANL_DBMplus.parquet" & model=="LANL-DBMplus", src:="EW43-LANL-DBMplus-2018-11-07"]

# KoT Adaptive - 2019-2020 - standardize names and infer date if not provided
data[src=="EW01-KoT-adaptive-2020-1-18.parquet" & model=="KoT-adaptive", src:="EW01-KoT-adaptive-2020-01-18.parquet"]
data[src=="EW02-KoT-adaptive-2020-2-5.parquet" & model=="KoT-adaptive", src:="EW02-KoT-adaptive-2020-02-05.parquet"]
data[src=="EW03-KoT-adaptive-2020-2-5.parquet" & model=="KoT-adaptive", src:="EW03-KoT-adaptive-2020-02-05.parquet"]
data[src=="EW43-KoT-adaptive-2019-11-6.parquet" & model=="KoT-adaptive", src:="EW43-KoT-adaptive-2019-11-06.parquet"]
data[src=="EW46-KoT-adaptive-2019-12-2.parquet" & model=="KoT-adaptive", src:="EW46-KoT-adaptive-2019-12-02.parquet"]
data[src=="EW47-KoT-adaptive-2019-12-9.parquet" & model=="KoT-adaptive", src:="EW47-KoT-adaptive-2019-12-09.parquet"]
data[src=="EW50-KoT-adaptive-2020-1-4.parquet" & model=="KoT-adaptive", src:="EW50-KoT-adaptive-2020-01-04.parquet"]
data[src=="EW51-KoT-adaptive-2020-1-4.parquet" & model=="KoT-adaptive", src:="EW51-KoT-adaptive-2020-01-04.parquet"]
data[src=="EW52-KoT-adaptive-2020-1-18.parquet" & model=="KoT-adaptive", src:="EW52-KoT-adaptive-2020-01-18.parquet"]

# GSU_extLog 2019 -  - standardize names and infer date if not provided
data[src=="EW52-GSU_extLog-2019-1-6_LATE.parquet", src:="EW52-GSU_extLog-2019-01-06_LATE.parquet"]

# there are some models that submit all NA rows for a particular combination
# of src (i.e. file), location, target, type
data[, to_drop:=all(is.na(value)), .(src, model, location, target, type)]
data <- data[to_drop==FALSE]

# get the date embedded within src
data[, src_date:=stringr::str_extract(src, "\\d{4}-\\d{2}-\\d{2}")]

# extract the unique rounds and counts
rounds = data[, .N, src_date][order(src_date)]

# First, lets handle the rows in `data` where the forecast_round_id is NA
# Its possible these were not handled correctly (this should be zero)
assertthat::are_equal(nrow(data[is.na(src_date)]), 0)

## Let's make epi week and year the round id
# first, get the epi week as listed in the source file
data[, ew:=as.integer(substr(src,3,4))]
# second, create forecast round as a combination of epi week and the year,
# where year choice in the season (first-second) is based on epiweek
data[ew<=18, forecast_round:=paste0(substr(yr,6,9), "-", substr(src,3,4))]
data[ew>18, forecast_round:=paste0(substr(yr,1,4), "-", substr(src,3,4))]


## correct the bin_end_notincl in cases where it is <NA>
## based on some exploration, it appears that there were some cases where 
## this value was <NA> when it should have been 100
## e.g. 
# tmpraw <- arrow::read_parquet(file = "./original_raw_data/2016-2017/Hist-Avg/EW43_Hist-Avg_2016-11-07.parquet")
# tmpraw %>% 
#   filter(is.na(bin_end_notincl))
data[is.na(bin_end_notincl) & type == "Bin", bin_end_notincl:=100]

# Columns
# - origin_epiweek ( we start with forecast_round from the raw data; 
#   other options here are convert this to a date (i.e. the saturday of this week), 
#   or use the saturday prior to the date in the file name)
# - target: This will be season onset wk, season peak wk, season pk percent, ili perc
# - horizon: This will be NA, except for ili perc, where it will be the first character
# - output_type: This will be pmf for season onset wk and season peak wk, will be cdf for
#   ili perc and season pk percent, and mean for all non Bin rows
# - output_type_id: This will be bin_end_notincl value for all cdf, will be bin_start_incl for all
#   pmf, and will be NA for mean
# - value: This will be value for all.

# Let's make a series of functions to convert each type of target, and each type of output type?

reduce_and_prepare_data <- function(
    df,
    cols = c("id", "src", "model", "forecast_round", "location", "target", "type", "unit", "bin_start_incl", "bin_end_notincl", "value")) {
  
  # reduce data
  df = df[, .SD, .SDcols = cols]
  
  # generate horizon
  df[, horizon:=fifelse(grepl("wk ahead", target), substr(target,1,1), NA_character_)]
  
  # revalue target:
  df[, target:=fcase(
    target == "Season onset", "season onset wk",
    target == "Season peak week", "season peak wk",
    target == "Season peak percentage", "season peak perc",
    default="ili perc"
  )]
  
  df
    
}

rename_cols <- function(
    df,
    new_names = c(
      "forecast_round"="origin_epiweek",
      "location" = "location",
      "target" = "target")) {
  setnames(df, old = names(new_names), new=new_names)
  
}

create_output_type_and_id <- function(df) {
  
  df[, output_type:=fcase(
    target %chin% c("season peak wk", "season onset wk") & type=="Bin", "pmf",
    target %chin% c("season peak perc", "ili perc") & type=="Bin", "cdf",
    type == "Point", "mean"
  )]
  
  # Now we create the output type id: This will be bin_end_notincl value for all cdf, will be bin_start_incl for all
  #   pmf, and will be NA for mean
  
  df[, output_type_id:=fcase(
    output_type == "cdf", bin_end_notincl,
    output_type == "pmf", bin_start_incl,
    output_type == "mean", NA_character_
  )]
  
  ## for some cdf model output type rows, there were floating point issues with output_type_id values
  ##   therefore, we decided to round and truncate digits for all output_type_id values
  ##   for cdf output_type rows
  df[output_type=="cdf", 
     output_type_id:=as.character(round(as.numeric(output_type_id), digits = 1))]

  ## for some pmf model output type rows, in the output_type_id column... 
  ##   (1) there are "-1" values where "none" should be present
  ##       e.g., see ./model-output/kot-adaptive/2019-11-09-kot-adaptive.parquet
  ##   (2) there are values like "40.0" where they should be integers. These
  ##       are instances where they are referring to an MMWR week which should
  ##       be defined by an integer.
  ##       e.g., see ./model-output/kot-adaptive/2019-11-23-kot-adaptive.parquet
  df[output_type=="pmf" & output_type_id == "-1", 
     output_type_id:="none"]
  df[output_type=="pmf" & output_type_id != "none", 
     output_type_id:=as.character(as.integer(output_type_id))]

  # Now, we have to adjust the value if we have cdf
  df[output_type=="cdf", value:=cumsum(value), by=.(src, model, origin_epiweek, location, target, horizon)]
  
}

cleanup <- function(
    df,
    cols = c("id", "src", "model", "origin_epiweek", "location", "target", "horizon", "output_type", "output_type_id", "value")) {
  
  df[, .SD, .SDcols = cols]

}

df = reduce_and_prepare_data(data)
rename_cols(df)
create_output_type_and_id(df)
df = cleanup(df)
gc()

# 4/15/24 - For now, we are going to keep the "last" of the 
# situations where there are multiple submissions within a 
# origin_epiweek for a model
k <- unique(df[, .(model, origin_epiweek,src)])
k <- k[order(origin_epiweek,model,src)]
k <- k[, .(src = last(src)), .(origin_epiweek,model)]
df <- merge(df, k, by=c("origin_epiweek", "model", "src"))

assertthat::are_equal(nrow(k[, .N, .(origin_epiweek,model)][N>1]),0)
gc()
setindex(df, NULL)
setkey(df, NULL)


#' Get start date of (epi) given epiweek and epiyear
#' 
#' Function returns the date of the first day of the epiweek defined by
#' user provided epiweek (`ew`) and epiyear (`ey`)
#' 
date_from_epiweekyear <- function(ey,ew) {
  # internal function gets the start date of the first week of year
  f <- \(y) { j4=paste0(y, "-01-04"); as.Date(j4) - wday(j4)+1}
  # get the start date of this epi year and next epi year
  s1 = f(ey); s2=f(ey+1)
  # check that max week is not exceeded  
  data.table::fifelse(ew>(f(ey+1) - s1)/7, NA_Date_, s1+(ew-1)*7)
}

origin_epiweeks = df[, unique(origin_epiweek)]
origin_date = as.Date(sapply(origin_epiweeks, \(oe) {
  date_from_epiweekyear(
    as.integer(substr(oe,1,4)),
    as.integer(substr(oe,6,7))
  )
}))

# Now, create look up table.. 
origin_epiweeks_lookup = data.table(
  origin_epiweek = origin_epiweeks,
  origin_date = origin_date + 6 # For now, we are just using the last
)
 
df <- df[origin_epiweeks_lookup, on="origin_epiweek"]


