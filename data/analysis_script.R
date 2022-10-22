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
library(gridExtra) # displaying plots side by side

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

# Collection date and creation date variables, extracting years
# There are 78 missing values in the Collection date variable which we infer from the Create date variable
df$Collection.date1 <- anydate(df$Collection.date)
df$Create.date1 <- format(as.Date(df$Create.date),format = "%Y-%m-%d")

# Extracting the month
df$Month <- format(as.Date(df$Collection.date1, format = "%Y-%m-%d"), "%m")

# Fill in NA values with month from Create.date
df$Month <- ifelse(is.na(df$Month),
                         format(as.Date(df$Create.date1), "%m"),
                         df$Month)

# Extracting the years
df$Year <- format(as.Date(df$Collection.date1, format = "%Y-%m-%d"), "%Y")

# Fill in NA values with year from Create.date
df$Year <- ifelse(is.na(df$Year), format(as.Date(df$Create.date1), "%Y"), df$Year)


# Cleaning up location variable and creating variable for state
# PR stands for Puerto Rico
df<- df %>%
  mutate(state = sub('.*:', '', Location))

# Replace all characters occurrence in a string
df$state[df$state == " Arizona" ] <- "AZ"
df$state[df$state == " CO" ] <- "CO"
df$state[df$state == " NC" ] <- "NC"
df$state[df$state == "Fl" ] <- "FL"

df$Location<- gsub(":.*$", "", df$Location)


# Aggregating IFSAC categories, Isolation source, Host, Host Disease
# Isolation sources
df$Isolation.source <- tolower(df$Isolation.source)

Sources <- df %>%
  group_by(Isolation.source) %>%
  summarise(N = n()) %>%
  mutate(Relative_Frequency = (N / sum(N))*100) %>%
  arrange(desc(Relative_Frequency))

# collapsing the sources based on the above frequencies
df <- df %>%
            mutate(Source =  ifelse(grepl("deli", Isolation.source), "deli", ifelse(grepl("chicken", Isolation.source), "chicken",ifelse(grepl("blood", Isolation.source), "blood",
                             ifelse(grepl("food", Isolation.source), "food", ifelse(grepl("pork", Isolation.source) | grepl("salami", Isolation.source)|grepl("ham", Isolation.source)|grepl("hog", Isolation.source)|grepl("swine", Isolation.source), "pork",
                             ifelse(grepl("beef", Isolation.source) | grepl("meat", Isolation.source), "beef",
                             ifelse(grepl("fecal", Isolation.source) | grepl("blood", Isolation.source)| grepl("tissue", Isolation.source)| grepl("rectal", Isolation.source) | grepl("feces", Isolation.source) |grepl("stool", Isolation.source), "stool",
                             ifelse(grepl("turkey", Isolation.source), "turkey", ifelse(grepl("dairy", Isolation.source)| grepl("cheese", Isolation.source)| grepl("ice cream", Isolation.source)| grepl("milk", Isolation.source), "dairy",
                             ifelse(grepl("environmental",Isolation.source) |grepl("environment", Isolation.source)|grepl("swab", Isolation.source), "environment",
                             ifelse(grepl("clinical",Isolation.source) |grepl("clincial", Isolation.source)|grepl("csf", Isolation.source) | grepl("cerebral", Isolation.source)| grepl("culture", Isolation.source) |grepl("fluid", Isolation.source), "clinical", 
                             ifelse(grepl("human", Isolation.source), "human",ifelse(grepl("farm", Isolation.source), "farm",
                             ifelse(grepl("poultry", Isolation.source), "poultry",ifelse(grepl("rte", Isolation.source), "rte products",ifelse(grepl("retail", Isolation.source)| grepl("retailer", Isolation.source), "retail",
                             ifelse(grepl("potato", Isolation.source), "potato",ifelse(grepl("water", Isolation.source) | grepl("drain", Isolation.source)| grepl("river", Isolation.source), "water",
                             ifelse(grepl("avocado", Isolation.source)|grepl("guacamole", Isolation.source), "avocado",
                             ifelse(grepl("blueberry", Isolation.source)| grepl("nectarines", Isolation.source)| grepl("peach", Isolation.source)| grepl("pico", Isolation.source)| grepl("cantaloupe", Isolation.source), "fruit",
                             ifelse(grepl("lettuce", Isolation.source), "lettuce", ifelse(grepl("egg", Isolation.source), "egg", ifelse(grepl("beet", Isolation.source), "beet",
                             ifelse(grepl("bean", Isolation.source)| grepl("sprout", Isolation.source), "beans", ifelse(grepl("vegetable", Isolation.source)| grepl("hummus", Isolation.source)| grepl("kale", Isolation.source), "vegetable",
                             ifelse(grepl("apple", Isolation.source), "apple",
                             ifelse(grepl("bovine", Isolation.source), "bovine", ifelse(grepl("brain", Isolation.source), "brain", ifelse(grepl("butchery", Isolation.source), "butchery", ifelse(grepl("shrimp", Isolation.source), "shrimp",
                             ifelse(grepl("mushroom", Isolation.source), "mushroom", ifelse(grepl("factory", Isolation.source), "factory", ifelse(grepl("feed", Isolation.source), "feed",
                             ifelse(grepl("fish", Isolation.source)| grepl("salmon", Isolation.source)|grepl("herring", Isolation.source)| grepl("tuna", Isolation.source), "fish",
                             ifelse(grepl("not available", Isolation.source)|grepl("not provided", Isolation.source)|grepl("not collected", Isolation.source) , "other/unspecified",
                             ifelse(is.na(Isolation.source), NA, "other/unspecified")))))))))))))))))))))))))))))))))))))

                                    
                            


################################################################################
## Missing data
################################################################################

# Missing values in all all variables

## overall missing data
sum(is.na(df))/prod(dim(df))*100 #23%
missing_values <- df %>% miss_var_summary()


# Visualization for percent missing
missing.values <- df %>%
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
  geom_bar(aes(x = reorder(key, desc(pct)), y = pct, fill=isna), stat = 'identity', alpha=0.8) +
  scale_x_discrete(limits = levels) +
  scale_fill_manual(name = "", values = c('steelblue', 'tomato3'), labels = c("Present", "Missing")) +
  theme(plot.caption = element_text(hjust = 0),
        plot.title = element_text(hjust = 0.5))+
  labs(title = "Percentage of missing values", 
       x = 'Variable', y = "% of missing values")+
  coord_flip() +
  theme_classic()
figure_one



################################################################################
## Exploratory Analysis
################################################################################

# Selecting columns for EDA
df_cols <- names(df)[c(9,25,29, 31,33:34, 39, 41, 43, 45:47, 53:56)]

# Data subset with variables of interest
df1 <- df[df_cols]

df1<- df1%>% filter(Year >= 2000)

# Number of organisms per year
table(df1$Organism.group, df1$Year)

# Summary counts for listeria monocytogenes over time
organism_summary <- df1 %>% 
  group_by(Year)%>%
  summarise(N = n()) %>% 
    mutate(Frequency = N/sum(N)*100)%>%
     arrange(Year)

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
  ggplot(aes(x= Year, y = N, group=1))+
  geom_point(size=2)+ geom_line(size=1.2) +
  theme(plot.title = element_text(hjust =0.5),
        plot.caption = element_text(hjust = 0))+
  scale_x_discrete(breaks= seq(2000,2025, by= 5))+
  labs(title = "Changes in Lm counts over time",
       x = "Year of Sample Collection", y= "Count")+
  theme_classic()


# Comparisons

# Proportions by Isolation type and year
summary_2<- df1 %>% 
  group_by(Isolation.type,Year)%>%
  summarise(N = n()) %>% 
  mutate(Frequency = N/sum(N)*100)

# Displaying counts of listeria monocytogenes by isolation type
figure_three <- summary_2 %>%
  ggplot(aes(x= Year, y = N, group= Isolation.type, color= Isolation.type))+
  geom_point(size=2)+ geom_line(size=1.2) +
  theme(plot.title = element_text(hjust =0.5),
        plot.caption = element_text(hjust = 0))+
  scale_x_discrete(breaks= seq(2000,2025, by= 5))+
  labs(title = "Changes in Lm counts over time", x = "Year of Sample Collection", y= "Count")+
  guides(color = guide_legend(title = "Types"))+
  theme_classic() +
  theme(legend.position="top")

# displaying figure two and three
grid.arrange(figure_two, figure_three, ncol=2)


# Summary counts for listeria monocytogenes over time by top isolation sources

# Proportions by Isolation type 
summary_3<- df1 %>% 
  group_by(Source)%>%
  summarise(N = n()) %>% 
  mutate(Frequency = N/sum(N)*100)%>%
  arrange(desc(Frequency))%>%
  head(n=20)

# Displaying table of top 20 Isolation sources
summary_3 %>%
  kable(caption = 
          "Proportion of Isolation sources for listeria monocytogenes",
        col.names = c("Source", "N", "Frequency"),
        digits = c(0, 0, 2),
        align = c("lll")) %>%
  kable_styling(latex_options = "HOLD_position") %>%
  column_spec(1, bold = TRUE) %>% row_spec(0, bold = TRUE)

# Year summary
summary_4 <- df1 %>% 
  group_by(Source, Year)%>%
  summarise(N = n()) %>% 
  mutate(Frequency = N/sum(N)*100)%>%
  arrange(N)

# line plots
figure_four <- summary_4%>% 
  filter(Source == "beef"| Source=="chicken"| Source=="pork" 
         |Source=="dairy")%>%
  ggplot(aes(x= Year, y = N, group= Source, color= Source))+
  geom_point(size=2)+ geom_line(size=1.2) +
  scale_x_discrete(breaks= seq(2000,2025, by= 5))+
  theme(plot.caption = element_text(hjust = 0))+
  labs(title = "Changes in Lm counts over time",
       x = "Year of Sample Collection", y= "Count")+
  theme_classic()+
  guides(color = guide_legend(title = ""))+
  theme(legend.position="top")

figure_five <- summary_4%>% 
  filter(Source == "water"| Source=="food" |
           Source=="potato"|Source=="fish")%>%
  ggplot(aes(x= Year, y = N, group= Source, color= Source))+
  geom_point(size=2)+ geom_line(size=1.2) +
  theme(plot.caption = element_text(hjust = 0))+
  scale_x_discrete(breaks= seq(2000,2025, by= 5))+
  labs(title = "Changes in Lm counts over time",
       x = "Year of Sample Collection", y= "Count")+
  theme_classic()+
  guides(color = guide_legend(title = ""))+
  theme(legend.position="top")


# displaying figure four and five
grid.arrange(figure_four, figure_five, ncol=2)


# Distribution of Min_same and Min_diff variables
df_distance <- df1[, c("Organism.group","Min.same", "Min.diff")] %>%
  pivot_longer(!Organism.group, names_to = "Type", values_to = "Value")

# Displaying plot of untransformed values
figure_six <- df_distance %>% ggplot(aes(x = Value, col = Type)) + 
  geom_histogram(aes(y = ..density.., fill = Type), color= "black", alpha = 0.3, bins = 30) +
  geom_density(size = 0.8) + 
  facet_wrap(~ Type) +
  ggtitle("Distributions of Min Same and Min Difference variables") +
  theme(plot.title = element_text(hjust = 0.5))+
  theme_classic()+
  theme(legend.position="top")

# Log transformed distributions
figure_seven <- df_distance %>% ggplot(aes(x = log(Value), col = Type)) + 
  geom_histogram(aes(y = ..density..), color="black", bins = 30) +
  geom_density(size = 1) + 
  facet_wrap(~ Type) +
  theme(plot.title = element_text(hjust = 0.5))+
  ggtitle("Log transformed Distributions of Min Same and Min Difference variables") +
  guides(color = guide_legend(title = "Variable"))+
  theme_classic() +
  theme(legend.position="top")


