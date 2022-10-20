################################################################################
## Data analysis for the final project
## Amos Okutse
## Rophence Ojiambo
## Zexhuan Yu
## PHP2550 Practical Data Anlysis
################################################################################


# Load the required libraries for data analysis
library(tidyverse)
library(lubridate)
library(anytime) # dates
library(kableExtra)
library(naniar) # Missing data
library(tidyr) # for data cleaning
library(stringr) # for working with characters

################################################################################
# DATA AND VARIABLE DESCRIPTIONS
################################################################################
# loading in the data
listeria_data <- read.csv("data/listeria_isolates.csv")

## viewing variable names
names(listeria_data)
dim(listeria_data) # as of 10/18/2022 data has 53725 observations with 50 variables

## Table 1: Description of selected variables in the Listeria pathogen data set
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
################################################################################
## Data pre-processing
################################################################################
### convert characters to factors in the dataset
listeria_data <- listeria_data %>% 
  dplyr::mutate_if(is.character, as.factor)

### Replacing empty strings with NA value 
listeria_data[listeria_data == ""] <- NA
### create a subset of the data with isolates included if non missing location, isolation source, IFSAC category and in the US
df <- listeria_data
dim(df)
## filter out strains with missing location
df <- df %>% 
  filter(!is.na(Location))
dim(df) #47216 not NA
## filter out isolates with missing isolation source
df <- df %>% 
  filter(!is.na(Isolation.source))
dim(df) #38420 not NA
## filter out isolates with missing IFSAC food category
df <- df %>% 
  filter(!is.na(IFSAC.category))
dim(df) #16755 not NA
## filter to isolates only in the USA
df <-df[str_detect(df$Location, "USA"), ]
dim(df) #14810 obs
## drop the unused levels in the location variable to have 57 levels of the US
df$Location <- droplevels(df$Location)
## include only listeria monocytogenes
df <- df %>% 
  filter(Scientific.name == "Listeria monocytogenes")
dim(df) #14653 
## view the data structure
str(df)
## drop unused levels or levels with count zero from the data set
length(levels(df$Isolation.source))
df$Isolation.source <- droplevels(df$Isolation.source)
df$IFSAC.category<- droplevels(df$IFSAC.category)

## overall missing data
sum(is.na(df))/prod(dim(df))*100 #23%


#df$new=grepl("fish", df$Isolation.source, ignore.case = TRUE)




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


