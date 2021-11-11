# ---
# title: "Analysis of questions: pilot e02"
# author: "mcmoyer"
# date: "November 20, 2020"
# output: html_document
# ---

## Step 1: select stimuli for experiment

library(ggplot2)
library(tidyr)
library(dplyr)
library(lme4)
library(tidyverse)
theme_set(theme_bw())

this.dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(this.dir)
source("../../../../../analysis/helpers.R")
# Read the database into R.
corp = read.table("../../../../../corpus/results/swbd.tab",sep="\t",header=T,quote="")
# Read the data into R.
d1 = read.csv("../data/e04_pilot-merged.csv")

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
d <- left_join(d1, corp_match, by="tgrep_id")
d$time_in_minutes = as.numeric(as.character(d$time_in_minutes))
d$rating = as.numeric(d$rating)
# write.csv(df,"df_nested.csv")

# read in the contexts too:
d_contexts = read.csv("../../../../clean_corpus/04_experiment/pilot.txt",sep="\t",header=T,quote="")

names(d_contexts)[names(d_contexts) == "TGrepID"] <- "tgrep_id"

d <- left_join(d, d_contexts, by="tgrep_id")


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
  filter(tgrep_id %in% c("example1", "example2", "example3", "example4"))

############################################################
# look at just the first practice trial
prac_agr = practice %>%
  group_by(workerid,tgrep_id,paraphrase,rating) %>%
  summarise(count = n()) %>%
  group_by(workerid,tgrep_id) %>%
  mutate(total_per_ex = sum(count))
nrow(prac_agr)

prac_agr_rem = practice %>%
  group_by(workerid,tgrep_id,paraphrase,rating) %>%
  summarise(count = n()) %>%
  group_by(workerid,tgrep_id) %>%
  mutate(total_per_ex = sum(count)) %>%
  filter(total_per_ex > 4)
  # write.csv(.,"practice_to_edit.csv")
nrow(prac_agr_rem) # 150

fixed = read.csv("practice_edited.csv",header=TRUE)
nrow(fixed) # 68
head(fixed)
# remove that one column
fixed = fixed[c(2:7)]

head(fixed)
prac_agr_keep = practice %>%
  group_by(workerid,tgrep_id,paraphrase,rating) %>%
  summarise(count = n()) %>%
  group_by(workerid,tgrep_id) %>%
  mutate(total_per_ex = sum(count)) %>%
  filter(total_per_ex <= 4)
nrow(prac_agr_keep) # 392

practice_first = rbind(fixed,prac_agr_keep)
nrow(practice_first) #320


############################################################
agr = practice %>%
  group_by(tgrep_id, paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()
# View(agr)

labels = c("Who can help spread the word?","Where can I get coffee around here?","Who came to the party?","How do I get to Central Park?")
names(labels) = c("example1","example2","example3", "example4")
# View(labels)
ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position="dodge") +
  facet_wrap(~tgrep_id,labeller = labeller(tgrep_id = labels)) +
  ggsave("../graphs/pilot_practice_total_faceted_Sentence.pdf")
# theme(axis.text.x = element_text(angle = 90))


# controls
controls = d1 %>%
  filter(grepl("control",tgrep_id))

cntrls = read.csv("../../../../clean_corpus/controls.csv",header=TRUE,quote="")
names(cntrls)[names(cntrls) == "TGrepID"] <- "tgrep_id"
c <- left_join(controls, cntrls, by="tgrep_id")

agr = c %>%
  group_by(EntireSentence,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()
ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position="dodge") +
  facet_wrap(~EntireSentence, labeller = labeller(Sentence = label_wrap_gen(20))) +
  ggsave("../graphs/pilot_controls.pdf")


# test
test = d %>%
  filter(!tgrep_id %in% c("example1", "example2", "example3", "example4","bot_check")) %>%
  filter(!grepl("control",tgrep_id)) %>%
  mutate()

agr = test %>%
  group_by(Sentence,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position="dodge") +
  facet_wrap(~Sentence, labeller = labeller(Sentence = label_wrap_gen(30)))
  ggsave("../graphs/pilot_test.pdf")


# subject variablility
ggplot(test, aes(x=rating,fill=response)) +
  geom_histogram(stat="count") +
  facet_wrap(~workerid) +
  # ggsave("../graphs/pilot_test_faceted_bysubjects.pdf")

