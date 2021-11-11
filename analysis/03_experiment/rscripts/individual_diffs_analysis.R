# ---
# title: "Individual differences using KL divergence"
# author: "mcmoyer"
# date: "March 16, 2021"
# ---

## Step 1: select stimuli for experiment
library(tidyverse)
library(lme4)
library(lmerTest)
library(multcomp) # not available for this version of R
theme_set(theme_bw())

this.dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(this.dir)
source("../../helpers.R")

cbPalette <- c("#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73")

########################################################################
# Read the data into R.
d = read.csv("../data/normed.csv")

# look at the sum of KL divergences from each individual to each item mean 
head(d)

d_means <- d %>%
  group_by(Question, paraphrase) %>%
  summarize(mean_rating = mean(normed_rating))

# collapse three ratings into a data matrix
