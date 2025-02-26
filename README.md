# FluSight Forecasts (Hubverse Version)

This repo contains the original FluSight Forecast submissions (<https://github.com/cdcepi/FluSight-forecasts>), reformatted to align with the hubverse format. For further detailed information on the original submissions and the content/format of the original files, refer to the repository above.

## Original Submissions

Submissions were submitted by modeling teams and organized within season by the name or number of the submitting team; within each team-specific or model-specific folder, a series of .csv submissions were stored, with file names typically (but not always) in the format: \"EWXX-TeamXX-YYYY-MM-DD.csv\", where

-   **EWXX** is the latest MMWR week of data used in the forecast

-   **TeamXX** is the team name/number

-   **YYYY-MM-DD** is the date of forecast submission

There were four types of targets related to influenza-like illness: season onset, peak week, peak percentage, and week ahead forecasts (1, 2, 3, and weeks) of weighted ILINet percentage

A copy of all original submissions, organized by season/team (e.g. `2015-2016/TeamXX/`) can be found in `original_raw_data/`. All of the original submissions are stored in parquet format

## Conversion Approach

**To do**


## Scripts

Scripts to reproduce the steps taken to create this hubverse formatted version of the repo can be found in the `scripts/` folder.

## Accessing hub data on the cloud


To ensure greater access to the data created by and submitted to this hub, real-time copies of its model-output,
target, and configuration files are hosted on the Hubverse's Amazon Web Services (AWS) infrastructure,
in a public S3 bucket: `uscdc-flusight-hub-v1`.

**Note**: For efficient storage, all model-output files in S3 are stored in parquet format, even if the original
versions in the GitHub repository are .csv.

GitHub remains the primary interface for operating the hub and collecting forecasts from modelers.
However, the mirrors of hub files on S3 are the most convenient way to access hub data without using git/GitHub or
cloning the entire hub to your local machine.

The sections below provide examples for accessing hub data on the cloud, depending on your goals and
preferred tools. The options include:

| Access Method              | Description                                                                           |
| -------------------------- | ------------------------------------------------------------------------------------- |
| hubData (R)                | Hubverse R client and R code for accessing hub data                                   |
| Polars (Python)            | Python open-source library for data manipulation                                      |
| AWS command line interface | Download hub data to your machine and use hubData or Polars for local access          |

In general, accessing the data directly from S3 (instead of downloading it first) is more convenient. However, if
performance is critical (for example, you're building an interactive visualization), or if you need to work offline,
we recommend downloading the data first.

<!-------------------------------------------------- hubData ------------------------------------------------------->

<details>

<summary>hubData (R)</summary>

[hubData](https://hubverse-org.github.io/hubData), the Hubverse R client, can create an interactive session
for accessing, filtering, and transforming hub model output data stored in S3.

hubData is a good choice if you:

- already use R for data analysis
- want to interactively explore hub data from the cloud without downloading it
- want to save a subset of the hub's data (*e.g.*, forecasts for a specific date or target) to your local machine
- want to save hub data in a different file format (*e.g.*, parquet to .csv)

### Installing hubData

To install hubData and its dependencies (including the dplyr and arrow packages), follow the [instructions in the hubData documentation](https://hubverse-org.github.io/hubData/#installation).

### Using hubData

hubData's [`connect_hub()` function](https://hubverse-org.github.io/hubData/reference/connect_hub.html) returns an [Arrow
multi-file dataset](https://arrow.apache.org/docs/r/reference/Dataset.html) that represents a hub's model output data.
The dataset can be filtered and transformed using dplyr and then materialized into a local data frame
using the [`collect_hub()` function](https://hubverse-org.github.io/hubData/reference/collect_hub.html).

#### Accessing model output data

Below is an example of using hubData to connect to a hub on S3 and filter the model output data.

```r
library(dplyr)
library(hubData)

bucket_name <- "uscdc-flusight-hub-v1"
hub_bucket <- s3_bucket(bucket_name)
hub_con <- hubData::connect_hub(hub_bucket, file_format = "parquet", skip_checks = TRUE)
hub_con %>%
  dplyr::filter(target == "ili perc", output_type == "mean") %>%
  hubData::collect_hub()

# A tibble: 173,811 × 9
#    model_id  origin_date target   horizon location     origin_epiweek output_type
#  * <chr>     <date>      <chr>      <int> <chr>        <chr>          <chr>
#  1 02115-emm 2017-11-11  ili perc       1 US National  2017-45        mean
#  2 02115-emm 2017-11-11  ili perc       2 US National  2017-45        mean
#  3 02115-emm 2017-11-11  ili perc       3 US National  2017-45        mean
#  4 02115-emm 2017-11-11  ili perc       4 US National  2017-45        mean
#  5 02115-emm 2017-11-11  ili perc       1 HHS Region 1 2017-45        mean
#  6 02115-emm 2017-11-11  ili perc       2 HHS Region 1 2017-45        mean
#  7 02115-emm 2017-11-11  ili perc       3 HHS Region 1 2017-45        mean
#  8 02115-emm 2017-11-11  ili perc       4 HHS Region 1 2017-45        mean
#  9 02115-emm 2017-11-11  ili perc       1 HHS Region 2 2017-45        mean
# 10 02115-emm 2017-11-11  ili perc       2 HHS Region 2 2017-45        mean
```

- [full hubData documentation](https://hubverse-org.github.io/hubData/)

</details>

<!--------------------------------------------------- Polars ------------------------------------------------------->

<details>

<summary>Polars (Python)</summary>

The Hubverse team is currently developing a Python client (hubDataPy). Until hubDataPy is ready,
the [Polars](https://pola.rs/) library is a good option for working with hub data in S3.
Similar to pandas, Polars is based on dataframes and series. However, Polars has a more straightforward API and is
designed to work with larger-than-memory datasets.

Pandas users can access hub data as described below and then use the `to_pandas()` method to convert a Polars dataframe
to pandas format.

Polars is a good choice if you:

- already use Python for data analysis
- want to interactively explore hub data from the cloud without downloading it
- want to save a subset of the hub's data (*e.g.*, forecasts for a specific date or target) to your local machine
- want to save hub data in a different file format (*e.g.*, parquet to .csv)

### Installing polars

Use pip to install Polars:

```sh
pip install polars
```

### Using Polars

The examples below use the Polars
[`scan_parquet()` function](https://docs.pola.rs/api/python/dev/reference/api/polars.scan_parquet.html), which returns a
[LazyFrame](https://docs.pola.rs/api/python/stable/reference/lazyframe/index.html).
LazyFrames do not perform computations until necessary, so any filtering and transforms you apply to the data are
deferred until an explicit
[`collect()` operation](https://docs.pola.rs/api/python/stable/reference/lazyframe/api/polars.LazyFrame.collect.html#polars.LazyFrame.collect).

#### Accessing model output data

Get all model-output files.
This example uses
[glob patterns to read from data multiple files into a single dataset](https://docs.pola.rs/user-guide/io/multiple/#reading-into-a-single-dataframe).
It also uses the [`streaming` option](https://docs.pola.rs/user-guide/concepts/_streaming/) when collecting data, which
facilitates processing of datasets that don't fit into memory.

```python
import polars as pl

# create a LazyFrame for model-output files
lf = pl.scan_parquet(
    "s3://uscdc-flusight-hub-v1/model-output/*/*.parquet",
    storage_options={"skip_signature": "true"}
)

# optionally, apply filters or transforms to the LazyFrame
lf = lf.filter(
    pl.col("target") == "ili perc",
    pl.col("output_type") == "mean"
)

# use a collect operation to materialize the LazyFrame into a DataFrame
ili_perc_mean = lf.collect(streaming=True)
ili_perc_mean.select(["origin_epiweek", "location", "output_type", "value"])

# shape: (173_811, 4)
# ┌────────────────┬───────────────┬─────────────┬──────────┐
# │ origin_epiweek ┆ location      ┆ output_type ┆ value    │
# │ ---            ┆ ---           ┆ ---         ┆ ---      │
# │ str            ┆ str           ┆ str         ┆ f64      │
# ╞════════════════╪═══════════════╪═════════════╪══════════╡
# │ 2017-43        ┆ US National   ┆ mean        ┆ 1.620766 │
# │ 2017-43        ┆ US National   ┆ mean        ┆ 1.620766 │
# │ 2017-43        ┆ US National   ┆ mean        ┆ 1.620766 │
# │ 2017-43        ┆ US National   ┆ mean        ┆ 1.620766 │
# │ 2017-43        ┆ HHS Region 1  ┆ mean        ┆ 1.064077 │
# │ …              ┆ …             ┆ …           ┆ …        │
# │ 2019-18        ┆ HHS Region 9  ┆ mean        ┆ 1.3      │
# │ 2019-18        ┆ HHS Region 10 ┆ mean        ┆ 0.8      │
# │ 2019-18        ┆ HHS Region 10 ┆ mean        ┆ 1.0      │
# │ 2019-18        ┆ HHS Region 10 ┆ mean        ┆ 0.8      │
# │ 2019-18        ┆ HHS Region 10 ┆ mean        ┆ 0.8      │
# └────────────────┴───────────────┴─────────────┴──────────┘
```

Get the model-output files for a specific team (all rounds).
Like the prior example, this one uses glob patterns to read multiple files.

```python
import polars as pl

lf = pl.scan_parquet(
    "s3://uscdc-flusight-hub-v1/model-output/vt-epideep/*.parquet",
    storage_options={"skip_signature": "true"}
)
```

- [Full documentation of the Polars Python API](https://docs.pola.rs/api/python/stable/reference/)

</details>

<!--------------------------------------------------- AWS CLI ------------------------------------------------------->

<details>

<summary>AWS CLI</summary>

AWS provides a terminal-based command line interface (CLI) for exploring and downloading S3 files.
This option is ideal if you:

- plan to work with hub data offline but don't want to use git or GitHub
- want to download a subset of the data (instead of the entire hub)
- are using the data for an application that requires local storage or fast response times

### Installing the AWS CLI

- Install the AWS CLI using the
[instructions here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- You can skip the instructions for setting up security credentials, since Hubverse data is public

### Using the AWS CLI

When using the AWS CLI, the `--no-sign-request` option is required, since it tells AWS to bypass a credential check
(*i.e.*, `--no-sign-request` allows anonymous access to public S3 data).

> [!NOTE]
> Files in the bucket's `raw` directory should not be used for analysis (they're for internal use only).

List all directories in the hub's S3 bucket:

```sh
aws s3 ls uscdc-flusight-hub-v1 --no-sign-request
```

List all files in the hub's bucket:

```sh
aws s3 ls uscdc-flusight-hub-v1 --recursive --no-sign-request
```

Download the model-output files for a specific team:

```sh
aws s3 cp s3://uscdc-flusight-hub-v1/model-output/vt-epideep/ . --recursive --no-sign-request
```

- [Full documentation for `aws s3 ls`](https://docs.aws.amazon.com/cli/latest/reference/s3/ls.html)
- [Full documentation for `aws s3 cp`](https://docs.aws.amazon.com/cli/latest/reference/s3/cp.html)

</details>

## Acknowledgments

This repository follows the guidelines and standards outlined by the [hubverse](%5Burl%5D(https://hubdocs.readthedocs.io/en/latest/)), which provides a set of data formats and open source tools for modeling hubs.
