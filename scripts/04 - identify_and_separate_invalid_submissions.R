# We want to validate the final df before writing to the model_output folder
# Specifically, we will check if pmf sum to 1 and cdf does not have maximum
# above 1. These tasks will be removed and written to an excluded-data folder


rm(list=setdiff(ls(), "df"))
gc()

cols_to_keep <- names(df)[which(!names(df) %chin% c("id", "src"))]

# a task group is defined by:
# - origin_date, model, location, target, horizon, and output_type
df[, task_id:=.GRP, .(origin_date, model, location, target, horizon, output_type)]

evaluate_distr_func <- function(v, f=c("pmf","cdf"), threshold = 0.1) {
  f = match.arg(f)
  # if all NA, return 2 (invalid)
  if(all(is.na(v))) return(2)
  # get the approach to use - sum/max must be close to 1 if pmf/cdf, respectively
  funcs=list("pmf"=sum, "cdf" = max)
  diff = abs(1-funcs[[f]](v, na.rm = T))
  # return 0 if exact, 1 if within threshold, and 2 if invalid
  fcase(dplyr::near(diff,0),0,!dplyr::near(diff,0) & diff<=threshold,1,default=2)
}

# Simple normalizations for pmf and cdf
normalize_pmf <- \(v) v/sum(v,na.rm = T)
normalize_cdf <- \(v) v/max(v,na.rm = T)

# Get PMF class, normalize the near-valid, and save (to object) the invalids
df[output_type=='pmf', pmf_class:=evaluate_distr_func(value, "pmf"), .(task_id)]
df[pmf_class==1, value:=normalize_pmf(value), task_id]
invalid_pmfs <- df[pmf_class==2, .SD, .SDcols = cols_to_keep]

# Get CDF class, normalize the near-valid, and remove (to object) the invalids
df[output_type=='cdf', cdf_class:=evaluate_distr_func(value, "cdf"), .(task_id)]
df[cdf_class==1, value:=normalize_cdf(value), task_id]
invalid_cdfs <- df[cdf_class==2, .SD, .SDcols = cols_to_keep]

dir.create("../excluded_output/",showWarnings = F)
arrow::write_parquet(invalid_cdfs, "../excluded_output/invalid_cdfs.parquet")
arrow::write_parquet(invalid_pmfs, "../excluded_output/invalid_pmfs.parquet")

# Reduce df to those that are not invalid and revert to the cols to keep
df <- df[!df[pmf_class==2 | cdf_class==2, .(task_id)], on="task_id", .SD, .SDcols = cols_to_keep]
