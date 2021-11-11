# ---
# title: "Analysis of questions: pilot e01"
# author: "mcmoyer"
# date: "November 11, 2020"
# output: html_document
# ---

## Step 1: select stimuli for experiment
setwd("/Users/momo/Dropbox/Stanford/whquestions-tgrep2/experiments/01_experiment/01_pilot/results/rscripts/")
source("/Users/momo/Dropbox/Stanford/whquestions-tgrep2/analysis/helpers.R")
library(ggplot2)
library(tidyr)
library(dplyr)
library(lme4)
library(tidyverse)
theme_set(theme_bw())

# Read the database into R.
corp = read.table("/Users/momo/Dropbox/Stanford/whquestions-tgrep2/corpus/results/swbd.tab",sep="\t",header=T,quote="")
# Read the data into R.
d1 = read.csv("/Users/momo/Dropbox/Stanford/whquestions-tgrep2/experiments/01_experiment/01_pilot/results/pilot_e01-merged.csv")

str(d1)
# Rename the Item_ID variable in the database to Tgrep_ID
names(corp)[names(corp) == "Item_ID"] <- "tgrep_id"

# filter from the database the tgrep_ids from the data
corp_match = corp %>%
  filter(tgrep_id %in% d1$tgrep_id)

nrow(corp)
nrow(d1)
nrow(corp_match)

# join the two dataframes together 
# merging will remove the values of "tgrep_id" that aren't shared
# dm <- merge(d1, corp_match, by="tgrep_id")
# nrow(dm)
# left-join does not
df <- left_join(d1, corp_match, by="tgrep_id")
df$time_in_minutes = as.numeric(as.character(df$time_in_minutes))
# write.csv(df,"df_nested.csv")

head(df)
# until i can find a way to unnest, save this as csv and unnest in python,
# then read the csv back in here
str(d)

# separate the response column into two columns
d = df %>%
  separate(response,into=c("response","strange"),sep="\', ")
# remove punctuation
d$strange = as.factor(gsub("[[:punct:]]","",d$strange))
d$response = as.factor(gsub("[[:punct:]]","",d$response))
# View(d)

# read in the contexts too:
d_contexts = read.csv("../../../../clean_corpus/pilot1.txt",sep="\t",header=T,quote="")
head(d_contexts)
# look at comments
unique(d$subject_information.comments)

# fair price
ggplot(d, aes(x=subject_information.fairprice)) +
  geom_histogram(stat="count")
table(d$subject_information.fairprice)

# overall assessment
ggplot(d, aes(x=subject_information.enjoyment)) +
  geom_histogram(stat="count")

# gender
ggplot(d, aes(x=subject_information.gender)) +
  geom_histogram(stat="count")


# language
ggplot(d, aes(x=subject_information.language)) +
  geom_histogram(stat="count")

# education
ggplot(d, aes(x=subject_information.education)) +
  geom_histogram(stat="count")


# time_in_minutes
ggplot(d, aes(x=time_in_minutes)) +
  geom_histogram(stat="count")
mean(d$time_in_minutes)

# Practice trials
practice = d %>%
  filter(tgrep_id %in% c("example1", "example2", "example3", "example4")) %>%
  mutate(response = as.factor(response), strange = as.factor(strange))
# View(practice)

# LOOK ONLY AT THE FIRST response
# NEED TO FIGURE THIS OUT
practice_first_choice = practice %>%
  group_by(workerid) %>%
  arrange(slide_number_in_experiment) %>%
  filter(cumsum(slide_number_in_experiment)<1)
# View(practice_first_choice)
# library(data.table)
pfc = setDT(practice)[, .SD[1:(which.max(slide_number_in_experiment)-1)], by=workerid]

# what are the subjects doing

# something is wrong with the labels..it looks like example3 didn't get labeled properly
# ideally, we will want to look at the first attempts

# these numbers may be off because we tracked participants' first responses
agr = practice %>%
  group_by(slide_number_in_experiment, response) %>%
  summarize(count_response = n()) %>%
  group_by(slide_number_in_experiment) %>%
  mutate(prop = count_response/sum(count_response))
# View(agr)

ggplot(agr,aes(x=response, y=prop, fill=response)) +
  geom_bar(position="dodge",stat="identity") +
  facet_wrap(~slide_number_in_experiment)
  # ggsave("../graphs/pilot_practice_faceted_Sentence.pdf")
  # theme(axis.text.x = element_text(angle = 90))


# test
test = d %>%
  filter(!tgrep_id %in% c("example1", "example2", "example3", "example4","bot_check")) %>%
  mutate(response = as.factor(response), strange = as.factor(strange))

# why does this have the responses from non-test answers???
table(test$response)/length(test$response)

agr = test %>%
  select(Sentence,response,strange) %>%
  group_by(Sentence,response) %>%
  summarize(count_response = n()) %>%
  group_by(Sentence) %>%
  mutate(prop_response = count_response/sum(count_response)) %>%
  mutate(entropy_response = -sum(prop_response * log2(prop_response)))
# View(agr)
view(agr)

probs = prop.table(d$response)

sum(probs*log2(probs))

ggplot(test, aes(x=response)) +
  geom_histogram(stat="count")

ggplot(test, aes(x=response,fill=response)) +
  geom_histogram(stat="count") +
  facet_wrap(~Sentence)

ggplot(test, aes(x=response, fill=strange)) +
  geom_histogram(position="dodge",stat="count")+
  facet_wrap(~Sentence, labeller = labeller(Sentence = label_wrap_gen(20)))

# subject variablility
ggplot(test, aes(x=response,fill=response)) +
  geom_histogram(stat="count") +
  facet_wrap(~workerid) +
  ggsave("../graphs/pilot_test_faceted_bysubjects.pdf")

  
ggplot(agr,aes(x=response, y=prop_response, fill = response)) +
  geom_bar(position="dodge",stat="identity") +
  facet_wrap(~Sentence, labeller = labeller(Sentence = label_wrap_gen(20))) +
  ggsave("../graphs/pilot_test_faceted_Sentence.pdf")
  # theme(axis.text.x = element_text(angle = 60))

View(d_contexts)

agr_strange = test %>%
  group_by(Sentence,strange) %>%
  summarize(count_strange = n()) %>%
  group_by(Sentence) %>%
  mutate(prop_strange = count_strange/sum(count_strange)) %>%
  filter(strange %in% c("False")) %>%
  mutate(prop_is_strange = 1 - prop_strange)
View(agr_strange)

ggplot(agr_strange,aes(x=response, y=prop_is_strange, fill=response)) +
  geom_bar(stat="identity")
# theme(axis.text.x = element_text(angle = 60))

library(scales)
both_vars = merge(agr_strange,agr, by=c("Sentence"))
View(both_vars)

# plot prop_is_strange as a function of entropy_response
ggplot(both_vars, aes(x=prop_is_strange,y=entropy_response)) +
  geom_point(shape=16, size=6, aes(shape=Sentence, color=Sentence, size=Sentence))+
  geom_smooth() +
  scale_colour_discrete(labels = function(x) str_wrap(x, width = 20))
  # ggsave("../graphs/pilot_entropyXstrange.pdf")


# calculate entropy

