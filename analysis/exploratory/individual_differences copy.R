# ---
# title: "Looking at individual differences through KL divergce"
# author: "mcmoyer"
# date: "April 19, 2021"
# ---

## Step 1: select stimuli for experiment
library(lme4)
library(lmerTest)
library(multcomp) # not available for this version of R
library(tidyverse)
theme_set(theme_bw())

this.dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(this.dir)
source("../helpers.R")

cbPalette <- c("#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73")

########################################################################
# Read the data into R.