# data goes here!

# Required libraries
library(tidyverse)
library(lubridate)
library(anytime) # dates
library(kableExtra)
library(naniar) # Missing data


# loading in the data
listeria_data <- read.csv("data/listeria_isolates.csv")

# viewing first 6 rows
head(listeria_data)
dim(listeria_data) # as of 10/18/2022 data has 53725 observations with 50 variables

# Variable Descriptions

variables <- c("Organism group","Isolate","IFSAC category", "Isolation Source", "Isolation Type","Strain", "Host", "Host Disease",
               "Collection Date", "Create Date", "Outbreak", "BioSample", "Lat/Lon", "Location", "Min-Same", "Min Diff")
description <- c("The name of the taxonomy group that the isolate belongs to and is represented by the Genus species name, for our case we shall focus on Listeria monocytogenes.",
    "The unique Pathogen Detection accession of the isolate  where each accession has a prefix (PDT), which stands for Pathogen Detection Target.",
    "Categories of isolate sourcing information as developed by The Interagency Food Safety Analytics Collaboration (IFSAC).",
    "Provides information on the physical, environmental and/or local geographical source of the biological sample from which the sampled was derived.",
    "Contains categories of the isolation sources into either clinical or environmental/other groups.",
    "Denotes the microbial strain name used to distinguish a genetically distinct lineage separated from another strain by one or two mutations.",
    "Refers to the host species of the isolate such as Animal, Homo sapiens, Sheep, Pigeon, Horse and Guinea pig.",
    "Host disease matches the identified isolate to a disease origin, for example Listeriosis, gastroenteritis, Meningitis and Septicaemia.",
    "Gives the date the sample was collected.",
    "Gives the date on which the isolates were first seen by the Pathogen Detection system.",
    "Defines a way to group isolates that originated due to the same breakout among a specific group of people or within a specific area over a period of time.",
    "Describes the biological source materials used in experimental assay.",
    "Provides the geographical coordinates (latitude and longitude) of the location where the sample was collected.",
    "Provides the geographical origin of the sample (Country or Region).",
    "Represents the minimum single nucleotide polymorphism (SNP) distance to another isolate of the same isolation type for example, the minimum SNP distance from one clinical isolate to another clinical isolate.",
    "Represents the minimum SNP distance to another isolate of a different isolation type. For example, the minimum SNP difference from a clinical isolate to an environmental isolate.")

var_desc <- data.frame(Variable = variables, Description = description)
kable(var_desc, caption = "Variable Descriptions")%>%
  kable_styling(full_width = FALSE, latex_options = 
                  c("HOLD_position","stripped"))%>%
  column_spec(1, bold = TRUE)%>%
  row_spec(0, bold = TRUE) %>%
  column_spec(2, width = "30cm")


# Data pre-processing

# Replacing empty strings with NA value 
listeria_data[listeria_data == ""] <- NA

listeria_cols <- names(listeria_data)[c(9,25,27,29, 31:34, 39:43, 45:47)]

# Data subset with variables of interest
listeria_df <- listeria_data[listeria_cols]


# Missing data

# Missing values in all all variables
missing_values <- listeria_df %>% miss_var_summary()


# Visualization for percent missing
missing.values <- listeria_df %>%
  gather(key = "key", value = "val") %>%
  mutate(isna = is.na(val)) %>%
  group_by(key) %>%
  mutate(total = n()) %>%
  group_by(key, total, isna) %>%
  summarise(num.isna = n()) %>%
  mutate(pct = num.isna / total * 100)

# variables with missing values
levels <- (missing.values  %>% filter(isna == T) %>%     
             arrange(desc(pct)))$key

# displaying plot
figure_one <- missing.values %>%
  ggplot() +
  geom_bar(aes(x = reorder(key, desc(pct)), 
               y = pct, fill=isna), 
           stat = 'identity', alpha=0.8) +
  scale_x_discrete(limits = levels) +
  scale_fill_manual(name = "", 
                    values = c('steelblue', 'tomato3'), 
                    labels = c("Present", "Missing")) +
  coord_flip() +
  theme(plot.caption = element_text(hjust = 0),
        plot.title = element_text(hjust = 0.5))+
  labs(title = "Percentage of missing values", 
       x = 'Variable', y = "% of missing values",
       caption = "Figure 1. Missing values in baseline variables")
figure_one


# Exploratory analysis including any initial questions related to your direction.

# IFASC category
length(unique(listeria_df$IFSAC.category))  # 285 unique IFSAC category
length(unique(listeria_df$IFSAC.category))/nrow(listeria_df)  # 0.53%

# Host
length(unique(listeria_df$Host))  # 90 unique Host
length(unique(listeria_df$Host))/nrow(listeria_df)  # 0.17%

# Host Disease
length(unique(listeria_df$Host.disease))  # 67 unique Host Disease
length(unique(listeria_df$Host.disease))/nrow(listeria_df)  # 0.12%

# Strain
length(unique(listeria_df$Strain))  # 42,794 strains
length(unique(listeria_df$Strain))/nrow(listeria_df)  # 79.65%

# # Isolation source
length(unique(listeria_df$Isolation.source))  # 3084 unique isolation sources
length(unique(listeria_df$Isolation.source))/nrow(listeria_df)  # 5.74%

# Isolation type
table(listeria_df$Isolation.type) # clinical type = 17344 and environmental/other type = 30356 observations


# BioSamples
length(unique(listeria_df$BioSample))  # 53694 BioSamples
length(unique(listeria_df$BioSample))/nrow(listeria_df)  # 99.94%

# Isolate
length(unique(listeria_df$Isolate))  # 53725 unique Isolates
length(unique(listeria_df$Isolate))/nrow(listeria_df)  # 100%

# Collection date and creation date variables, extracting years
listeria_df$Collection.date <- anytime(listeria_df$Collection.date)
listeria_df$Collection.date <- format(as.Date(listeria_df$Create.date),'%Y')
listeria_df$Create_Date <- format(as.Date(listeria_df$Create.date),'%Y')

table(listeria_df$Organism.group, listeria_df$Collection.date)

# Summary counts for listeria monocytogenes over time
organism_summary <- listeria_df %>% 
  group_by(Collection.date)%>%
  summarise(N = n()) %>% 
    mutate(Frequency = N/sum(N)*100)

# Displaying table
organism_summary %>%
  kable(caption = 
          "Summary counts listeria monocytogenes over time",
        col.names = c("Year", "N", "Relative Frequency"),
        digits = c(0, 0, 4),
        align = c("lcc")) %>%
  kable_styling(latex_options = "HOLD_position") %>%
  column_spec(1, bold = TRUE) %>% row_spec(0, bold = TRUE)

# Displaying overall line plot of counts listeria monocytogenes over time
figure_two <- organism_summary %>%
  ggplot(aes(x= Collection.date, y = N, group=1))+
  geom_point(size=3)+
  geom_line(size=1.2) +
  theme(plot.title = element_text(hjust =0.5),
        plot.caption = element_text(hjust = 0))+
  labs(title = "Changes in listeria monocytogenes counts over time",
       x = "Year of Sample Collection", y= "Count",
       caption = "Figure 2. Line plot of listeria monocytogenes counts over time")
figure_two


# Aggregating IFSAC categories, Isolation source, Host, Host Disease


