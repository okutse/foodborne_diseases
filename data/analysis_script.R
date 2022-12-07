################################################################################
## Data analysis for the final project in Practical Data Analysis
## Amos Okutse
## Rophence Ojiambo
## Zexhuan Yu
## PHP2550 Practical Data Analysis
################################################################################


# Load the required libraries for data analysis
library(tidyverse)     ## for data analysis pipelines
library(lubridate)     ## for working with dates
library(anytime)       ## for working with dates
library(kableExtra)
library(naniar)        ## for handling missing data
library(tidyr)         ## for data cleaning
library(stringr)       ## for working with characters
library(gridExtra)     ## displaying plots side by side
library(ROSE)          ## handling class imbalance

##########################################
## Modeling Libraries
##########################################
library(rsample)
library(tidymodels)    ## for using tidy models in R
library(broom.mixed)   ## for converting Bayesian models to tidy tibbles
library(dotwhisker)    ## for visualizing regression results
library(naivebayes)    ## implementation of the naive Bayes algorithm
library(discrim)       ## the required extension package for using the `naivebayes` engine in parsnip
library(vip)           ## for plotting variable importance
library(themis)        ## recipe steps for dealing with unbalanced datasets
library(bonsai)        ## to use lightgbm engine
library(lightgbm)      ##  lightgbm

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
               "Collection Date", "Create Date", "Outbreak", "BioSample", "Lat/Lon", "Location", "Min-Same", "Min Diff", "Serovar", "AMR Genotypes", "SNP Cluster")
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
    "Represents the minimum SNP distance to another isolate of a different isolation type. For example, the minimum SNP difference from a clinical isolate to an environmental isolate.",
    "Represents the combined field of sub-species, serotype, or serovar",
    "Provides information on the antimicrobial resistance (AMR) genes found in each isolate.",
    "Represents single nucleotide polymorphisms (SNP) clusters, where the genome assemblies are closely linked to each other.")

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
# DC stands for District of Columbia
# USA state renamed to "other"
df<- df %>%
  mutate(state = sub('.*:', '', Location))

# Replace all characters occurrence in a string
df$state[df$state == " Arizona" ] <- "AZ"
df$state[df$state == " CO" ] <- "CO"
df$state[df$state == " NC" ] <- "NC"
df$state[df$state == "Fl" ] <- "FL"
df$state[df$state == "USA" ] <- "Other"


df$Location<- gsub(":.*$", "", df$Location)

# looking at seasonality
# We want to look at seasonality 
df$Month <- as.numeric(df$Month)
df <- df %>% mutate(season =case_when(Month == 1 ~ "Winter",  Month == 2 ~ "Winter",
                           Month == 3 ~ "Spring", Month == 4 ~ "Spring",
                           Month == 5 ~ "Spring", Month == 6 ~ "Summer",
                           Month == 7 ~ "Summer", Month == 8 ~ "Summer",
                           Month == 9 ~ "Fall", Month == 10 ~ "Fall",
                           Month == 11 ~ "Fall", Month == 12 ~ "Winter"))

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
  mutate(Source1 = ifelse(grepl("deli", Isolation.source), "deli", ifelse(grepl("chicken", Isolation.source), "chicken",ifelse(grepl("blood", Isolation.source), "blood",
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



                                                               
# further collapsing the categories
df <- df %>%
      mutate(Source2 = ifelse(grepl("environmental",Isolation.source) |grepl("environment", Isolation.source)|grepl("swab", Isolation.source) |grepl("water", Isolation.source) | grepl("drain", Isolation.source)| grepl("river", Isolation.source) | grepl("soil", Isolation.source)| grepl("wheel", Isolation.source), "environment",
                        ifelse(grepl("dairy", Isolation.source)| grepl("cheese", Isolation.source)| grepl("cream", Isolation.source)| grepl("milk", Isolation.source)| grepl("egg", Isolation.source)| grepl("yogurt", Isolation.source)| grepl("butter", Isolation.source), "dairy",
                          ifelse(grepl("clinical",Isolation.source) |grepl("clincial", Isolation.source)|grepl("csf", Isolation.source) | grepl("cerebral", Isolation.source)| grepl("culture", Isolation.source) |grepl("fluid", Isolation.source)|grepl("human", Isolation.source)|grepl("blood", Isolation.source)|
                                grepl("fecal", Isolation.source) | grepl("blood", Isolation.source)| grepl("tissue", Isolation.source)| grepl("rectal", Isolation.source) | grepl("feces", Isolation.source) |grepl("stool", Isolation.source) | grepl("brain", Isolation.source), "human",
                            ifelse(grepl("beef", Isolation.source) | grepl("bovine", Isolation.source)|grepl("cow", Isolation.source)| grepl("cattle", Isolation.source)|grepl("calf", Isolation.source)|grepl("meat", Isolation.source)|grepl("pork", Isolation.source) | grepl("salami", Isolation.source)|
                                     grepl("ham", Isolation.source)|grepl("hog", Isolation.source)|grepl("swine", Isolation.source)|grepl("porcine", Isolation.source), "meat",
                              ifelse(grepl("chicken", Isolation.source)|grepl("poultry", Isolation.source)|grepl("turkey", Isolation.source)|grepl("sponge", Isolation.source), "poultry",      
                                  ifelse(grepl("kale", Isolation.source)|grepl("lettuce", Isolation.source)|grepl("beet", Isolation.source)|grepl("spinach", Isolation.source)| grepl("microgreen", Isolation.source)|grepl("collard", Isolation.source)|grepl("leaf", Isolation.source)|grepl("cabbage", Isolation.source)|
                                          grepl("chard", Isolation.source)|grepl("brocco", Isolation.source)|grepl("parsley", Isolation.source)|grepl("cilantro", Isolation.source)|grepl("basil", Isolation.source)|grepl("spring", Isolation.source), "leafy_greens",
                                    ifelse(grepl("potato", Isolation.source)|grepl("vegetable", Isolation.source)| grepl("hummus", Isolation.source)|grepl("bean", Isolation.source)| grepl("sprout", Isolation.source)|grepl("mushroom", Isolation.source)|grepl("corn", Isolation.source), "vegetables",      
                                      ifelse(grepl("avocado", Isolation.source)|grepl("guacamole", Isolation.source)|grepl("blueberry", Isolation.source)| grepl("nectarines", Isolation.source)| grepl("peach", Isolation.source)| grepl("pico", Isolation.source)| grepl("cantaloupe", Isolation.source)|grepl("apple", Isolation.source), "fruits",         
                                        ifelse(grepl("shrimp", Isolation.source)|grepl("fish", Isolation.source)| grepl("salmon", Isolation.source)|grepl("herring", Isolation.source)| grepl("tuna", Isolation.source), "sea_food",
                                           ifelse(grepl("not available", Isolation.source)|grepl("not provided", Isolation.source)|grepl("not collected", Isolation.source) , "other",
                                                  ifelse(is.na(Isolation.source), "NA", "other"))))))))))))

                                    

# creating new SNP cluster variable
# Summary counts for listeria monocytogenes over time
SNP_summary <- df %>% 
  group_by(SNP.cluster)%>%
  summarise(N = n()) %>% 
  mutate(Frequency = N/sum(N)*100)%>%
  arrange(desc(N))

df <- df %>%
  mutate(snp_cluster = ifelse(grepl("PDS000000366.504",SNP.cluster), "PDS000000366.504",
                       ifelse(grepl("PDS000024989.120", SNP.cluster), "PDS000024989.120",
                       ifelse(grepl("PDS000024934.85",Isolation.source), "PDS000024934.85",
                       ifelse(grepl("PDS000024311.16", Isolation.source), "PDS000024311.16",
                       ifelse(grepl("PDS000058430.33", Isolation.source), "PDS000058430.33",      
                       ifelse(grepl("PDS000025154.24", Isolation.source), "PDS000025154.24",
                       ifelse(grepl("PDS000025433.69", Isolation.source), "PDS000025433.69",      
                       ifelse(grepl("PDS000058419.26", Isolation.source), "PDS000058419.26",         
                       ifelse(grepl("PDS000025233.7", Isolation.source), "PDS000025233.7",
                       ifelse(grepl("PDS000024349.25", Isolation.source) , "PDS000024349.25",
                       ifelse(grepl("PDS000083553.8", Isolation.source) , "PDS000083553.8",
                       ifelse(grepl("PDS000024647.66", Isolation.source) , "PDS000024647.66",
                       ifelse(grepl("PDS000000270.29", Isolation.source) , "PDS000000270.29",
                       ifelse(grepl("PDS000003277.110", Isolation.source) , "PDS000003277.110",
                       ifelse(grepl("PDS000024645.152", Isolation.source) , "PDS000024645.152",
                       ifelse(grepl("PDS000003294.17", Isolation.source) , "PDS000003294.17",
                       ifelse(grepl("PDS000024856.163", Isolation.source) , "PDS000024856.163",
                       ifelse(is.na(Isolation.source), "Unknown", "Others")))))))))))))))))))





################################################################################
## Missing data
################################################################################

# Missing values in all all variables

## overall missing data
sum(is.na(df))/prod(dim(df))*100 #20.4455%
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

# Restricting to only variables that have NA values and arranging in descending order
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
df_cols <- names(df)[c(9,23,25,26,29, 31, 33:34, 38,39, 41:43, 45:47, 49, 53:59)]

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
        align = c("lcc"),
        booktabs = TRUE) %>%
  kable_styling(latex_options = "HOLD_position") %>%
  column_spec(1, bold = TRUE) %>% row_spec(0, bold = TRUE)

# Displaying overall line plot of counts listeria monocytogenes over time
figure_two <- organism_summary %>%
  ggplot(aes(x= Year, y = N, group=1))+
  geom_point(size=2)+ geom_line(size=1.2) +
  theme(plot.title = element_text(hjust =0.5),
        plot.caption = element_text(hjust = 0))+
  scale_x_discrete(breaks= seq(2000,2025, by= 5))+
  labs(title = "(a)",
       x = "Year of Sample Collection", y= "Count")+
  theme_classic()


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
  labs(title = "(b)", x = "Year of Sample Collection", y= "Count")+
  guides(color = guide_legend(title = "Types"))+
  theme_classic() +
  theme(legend.position="top")

# Summary counts for listeria monocytogenes by Month
month_summary <- df1 %>% 
  group_by(Isolation.type,Month)%>%
  summarise(N = n()) %>% 
  mutate(Frequency = N/sum(N)*100)%>%
  select(-N)%>%
  arrange(Month) 
month_summary$Isolation.type <- str_replace(month_summary$Isolation.type, "environmental/other", "Environmental")

month_summary[,3] = round(month_summary[,3],2)
month_summary[, -c(1,2)] <- data.frame (matrix(paste0(as.matrix(month_summary[, -c(1,2)]), '%'), ncol=1))

month_summary<- month_summary %>% pivot_wider(names_from = Month, values_from = Frequency)


# Summary counts for listeria monocytogenes by state
state_summary <- df1 %>% 
  group_by(state)%>%
  summarise(N = n()) %>% 
  mutate(Frequency = N/sum(N)*100)%>%
  arrange(desc(N)) 
state_summary[,3] = round(state_summary[,3],2)


# Displaying table
month_summary %>%
  kable(caption = 
          "Counts of $\\textit{Listeria monocytogenes}$ by month",
        col.names = c("Isolation type", "Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sep", "Oct", "Nov", "Dec"),
        digits = 2,
        align = c("llllllllllll"),
        booktabs = TRUE) %>%
  kable_styling(latex_options = "HOLD_position") %>%
  column_spec(1, bold = TRUE)
# Summary counts for listeria monocytogenes over time by top isolation sources

# Proportions by Isolation type 
summary_3<- df1 %>% 
  group_by(Source2)%>%
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
  group_by(Source1, Year)%>%
  summarise(N = n()) %>% 
  mutate(Frequency = N/sum(N)*100)%>%
  arrange(N)

# line plots

# figure four
figure_four <- summary_4%>% 
  filter(Source1 == "beef"| Source1=="chicken"| Source1=="pork" 
         |Source1=="dairy")%>%
  ggplot(aes(x= Year, y = N, group= Source1, color= Source1))+
  geom_point(size=2)+ geom_line(size=1.2) +
  scale_x_discrete(breaks= seq(2000,2025, by= 5))+
  theme(plot.caption = element_text(hjust = 0))+
  labs(title = "(a)",
       x = "Year of Sample Collection", y= "Count")+
  theme_classic()+
  guides(color = guide_legend(title = ""))+
  theme(legend.position="top")

# Displaying figure 5
figure_five <- summary_4%>% 
  filter(Source1 == "water"| Source1=="food" |
           Source1 =="potato"|Source1 =="fish")%>%
  ggplot(aes(x= Year, y = N, group= Source1, color= Source1))+
  geom_point(size=2)+ geom_line(size=1.2) +
  theme(plot.caption = element_text(hjust = 0))+
  scale_x_discrete(breaks= seq(2000,2025, by= 5))+
  labs(title = "(b)",
       x = "Year of Sample Collection", y= "Count")+
  theme_classic()+
  guides(color = guide_legend(title = ""))+
  theme(legend.position="top")


# Distribution of Min_same and Min_diff variables
df_distance <- df1[, c("Organism.group","Min.same", "Min.diff")] %>%
  pivot_longer(!Organism.group, names_to = "Type", values_to = "Value")

# Displaying plot of un-transformed values
figure_six <- df_distance %>% ggplot(aes(x = Value, col = Type)) + 
  geom_histogram(aes(y = ..density.., fill = Type), color= "black", alpha = 0.3, bins = 30) +
  geom_density(size = 0.8) + 
  facet_wrap(~ Type) +
  labs(y="Density")+
  ggtitle("") +
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





################################################################################
## METHODOLOGY: STATISTICAL MODELING
################################################################################



## In the current study, we investigated the potential of machine learning to predict the food source origins of bacterial
##strains isolated from human cases of listeriosis using machine learning analyses of pathogenic data. Our machine learning model was able to recognize patterns in the complex data set
##and use this information to predict the source of human listeriosis isolates. 

################################################################################

sub_dfx <- df %>% 
  dplyr::select(c("Source2", "Min.same", "Min.diff", "Strain", "Isolate", "state", "snp_cluster", "season"))

sub_dfx <- na.omit(sub_dfx)
saveRDS(sub_dfx, "data\\final_df.RData")
write.csv(sub_dfx, "data\\final_df.csv", row.names = FALSE)

## Explore the class proportions
tab <- sub_dfx %>% dplyr::group_by(Source2) %>% 
  dplyr::summarise(count = n())
tab

sub_dfx <- sub_dfx %>% 
  dplyr::mutate_if(is.character, as.factor)
## Create data partition
set.seed(123)
df_split <- sub_dfx %>% 
  initial_split(strata = Source2, 
                prop = 3/4)


## get the actual train and test data sets
train <- training(df_split)
test  <- testing(df_split)

## save the test and train datasets
write.csv(train, "data\\train.csv", row.names = FALSE)
write.csv(train, "data\\test.csv", row.names = FALSE)


nrow(train)
nrow(train)/nrow(sub_dfx) ## 74%


# training set proportions by food source
train.prop <- train %>% 
  count(Source2) %>% 
  mutate(prop = n/sum(n))


# test set proportions by food source
test.prop <- test %>% 
  count(Source2) %>% 
  mutate(prop = n/sum(n))


test_train_prop <- bind_cols(list(train.prop, test.prop)) %>% 
  dplyr::select(c(1, 2, 3, 5, 6))
names(test_train_prop) <- c("Food source", "Train set sample size", "Train set proportion", "Test set sample size", "Test set proportion" )
test_train_prop



##------------------------------------------------------------------------------
## (1) Naive Bayes [Model corrected for class imbalance and cross-validated]
##------------------------------------------------------------------------------

## Initial model builds
class_metrics <- metric_set(accuracy, roc_auc, kap, j_index, sens, spec)

## create a recipe 
nb <- recipe(Source2 ~ ., data = train) %>% 
  step_upsample(Source2, over_ratio = 1) # %>% 
  #step_rose(Source2, seed = 123)


nb_model <- naive_Bayes(Laplace = 1) %>% 
  set_mode("classification") %>% 
  set_engine("naivebayes")

## build workflow
nb_wkflw <- workflow() %>% 
  add_model(nb_model) %>% 
  add_recipe(nb)

## creates folds for cross-validation
set.seed(123)
folds <- vfold_cv(train, v = 10, strata = Source2)
set.seed(123)

nb_results <- fit_resamples(
  nb_wkflw,
  resamples = folds,
  metrics = class_metrics
)

## collect the metrics on the training data set
naive_train <- collect_metrics(nb_results)
naive_train


## fit the model on up-sampled data and use to make predictions on the test set
up_naive_model <- workflow() %>%
  add_recipe(nb) %>%
  add_model(nb_model) %>%
  fit(train) 

  ## get the accuracy for the non-cross validated Naive Bayes
acc = predict(up_naive_model, test) %>% 
  bind_cols(test) %>% 
  metrics(truth = Source2, estimate = .pred_class)
acc


## compute the final metrics for presentation [reported in paper]
final_metrics <- predict(up_naive_model, test, type = "prob") %>%
  bind_cols(predict(up_naive_model, test)) %>%
  bind_cols(select(test, Source2)) %>%
  class_metrics(Source2, .pred_dairy:.pred_vegetables, estimate = .pred_class)
final_metrics


## plot the AUC: first get predicted probabilities on the test set then use these for the plot for each potential food source
naive_probs <- predict(up_naive_model, test, type = "prob") %>%
  bind_cols(test) %>% 
  glimpse()


# Gain curve for each food source
naive_gain <- naive_probs %>%
  gain_curve(Source2, .pred_dairy:.pred_vegetables) %>%
  autoplot()
naive_gain


# ROC curve for each food source
naive_ROC <- naive_probs %>%
  roc_curve(Source2, .pred_dairy:.pred_vegetables) %>%
  autoplot()
naive_ROC


## save the naive gain curve to figures folder
jpeg("figures\\naive_gain_cv.jpeg", width = 4, height = 4, units = 'in', res = 300)
naive_gain
dev.off()


jpeg("figures\\naive_ROC_cv.jpeg", width = 4, height = 4, units = 'in', res = 300)
naive_ROC
dev.off()






##------------------------------------------------------------------------------
### (2) Naive Bayes [Model not corrected for class imbalance and not cross-validated]
##------------------------------------------------------------------------------

#use Laplace smoothing here to handle zero probabilities: value proposed here
#naiveModel <- naive_Bayes(Laplace = 1) %>% 
#  set_mode("classification") %>% 
#  set_engine("naivebayes") %>% 
#  fit(Source2 ~., data = train)


## can predict using this model on the test set
#naive_pred <- predict(naiveModel, test, type = "class")
   
## get the accuracy for the non-cross validated Naive Bayes
# acc = predict(naiveModel, test) %>% 
#   bind_cols(test) %>% 
#   metrics(truth = Source2, estimate = .pred_class)
 

## compute the final metrics for presentation 
# final_metricsx <- predict(naiveModel, test, type = "prob") %>%
#   bind_cols(predict(naiveModel, test)) %>%
#   bind_cols(select(test, Source2)) %>%
   #metrics(Source2, .pred_dairy:.pred_vegetables, estimate = .pred_class)
# class_metrics(Source2, .pred_dairy:.pred_vegetables, estimate = .pred_class)
 #final_metricsx
 
 
## plot the AUC: first get predicted probabilities on the test set then use these for the plot for each potential food source
#naive_probs <- predict(naiveModel, test, type = "prob") %>%
#  bind_cols(test) %>% 
#  glimpse()
 
 
          # Gain curve for each food source
#naive_gain <- naive_probs %>%
#  gain_curve(Source2, .pred_dairy:.pred_vegetables) %>%
#  autoplot()
#naive_gain


          # ROC curve for each food source
#naive_ROC <- naive_probs %>%
#  roc_curve(Source2, .pred_dairy:.pred_vegetables) %>%
#  autoplot()
#naive_ROC


## save the naive gain curve to figures folder
#jpeg("figures\\naive_gain.jpeg", width = 4, height = 4, units = 'in', res = 300)
#naive_gain
#dev.off()


#jpeg("figures\\naive_ROC.jpeg", width = 4, height = 4, units = 'in', res = 300)
#naive_ROC
#dev.off()

##------------------------------------------------------------------------------  
### (2) Random forest [cross-validated and corrected for class imbalance]
##------------------------------------------------------------------------------
#cores <- parallel::detectCores()
#cores

## create the random forest model
rf_model <- rand_forest(trees = 500, mtry = tune(), min_n = tune()) %>% 
  set_engine("ranger") %>% 
  set_mode("classification") #%>% 
  #fit(Source2 ~ ., data = train) 

## create a recipe 
rf_recipe <- recipe(Source2 ~ ., data = train) %>% 
  step_upsample(Source2, over_ratio = 1) 

## create the rf workflow
rf_workflow <- 
  workflow() %>% 
  add_model(rf_model) %>% 
  add_recipe(rf_recipe)

## create the validation set [80%] for parameter tuning
set.seed(234)
val_set <- validation_split(train, 
                            strata = Source2, 
                            prop = 0.80)
val_set

## set up the tuning grid [commented out after run due to computational intensity]
#set.seed(345)
#rf_res <- 
#  rf_workflow %>% 
#  tune_grid(val_set,
#            grid = 25,
#            control = control_grid(save_pred = TRUE),
#            metrics = metric_set(roc_auc))

## show the top 5 best rf models based on AUC
#rf_res %>% 
#  show_best(metric = "roc_auc")

## plot the best models using AUC values [show supplementary]
#autoplot(rf_res)

## select the best model based on the AUC
#rf_best <- 
#  rf_res %>% 
#  select_best(metric = "roc_auc")
#rf_best  ##[mtry = 2, min_n = 3] are best parameters 3 and 7


## re-fit model using best parameters based on the tuning process
rf_model_tuned <- rand_forest(trees = 500, mtry = 2, min_n = 3) %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

rf_workflow <- 
  workflow() %>% 
  add_model(rf_model_tuned) %>% 
  add_recipe(rf_recipe)

rf_results <- fit_resamples(
  rf_workflow,
  resamples = folds,
  metrics = class_metrics
)

## collect the metrics on the training data set
rf_train <- collect_metrics(rf_results)
rf_train

## fit the model on the full training dataset to make predictions on test set
up_rf_model <- workflow() %>% 
  add_model(rf_model_tuned) %>% 
  add_recipe(rf_recipe) %>% 
  fit(train)


## compute the final metrics for the random forest model [reported in paper]
rf_test_metrics <- predict(up_rf_model, test, type = "prob") %>%
  bind_cols(predict(up_rf_model, test)) %>%
  bind_cols(select(test, Source2)) %>%
  #metrics(Source2, .pred_dairy:.pred_vegetables, estimate = .pred_class)
  class_metrics(Source2, .pred_dairy:.pred_vegetables, estimate = .pred_class)
rf_test_metrics


## gain and AUC curves [presented as supplementary materials]
## plot the AUC: first get predicted probabilities on the test set then use these for the plot for each potential food source
rf_probs <- predict(up_rf_model, test, type = "prob") %>%
  bind_cols(test) %>% 
  glimpse()


# Gain curve for each food source
rf_gain <- rf_probs %>%
  gain_curve(Source2, .pred_dairy:.pred_vegetables) %>%
  autoplot()
rf_gain


# ROC curve for each food source
rf_ROC <- rf_probs %>%
  roc_curve(Source2, .pred_dairy:.pred_vegetables) %>%
  autoplot()
rf_ROC


## save the naive gain curve to figures folder
jpeg("figures\\rf_gain_cv.jpeg", width = 4, height = 4, units = 'in', res = 300)
rf_gain
dev.off()

jpeg("figures\\rf_ROC_cv.jpeg", width = 4, height = 4, units = 'in', res = 300)
rf_ROC
dev.off()

##------------------------------------------------------------------------------
## Performance measures [Table should be in paper]
##------------------------------------------------------------------------------

## Performance of the models across 10 folds
naive_metrics <- naive_train %>% dplyr::select(.metric, mean, std_err)
rf_metrics <- rf_train %>% dplyr::select(.metric, mean, std_err)
cv_metrics <- bind_cols(list(naive_metrics, rf_metrics))
cv_metrics <- as.data.frame(cv_metrics)
rownames(cv_metrics) <- c("Accuracy", "Jaccard's index", "Kappa", "AUC", "Sensitivity", "Specificity")
performance = kable(cv_metrics, format = "latex", caption = "Model performance measures across 10 folds with resampling for Naive Bayes and random forest classification algorithms",
      digits = 4, booktabs = TRUE, col.names = c("Metric", "Estimate", "Standard error (SE)", "Metric", "Estimate", "Standard error (SE)")) %>% 
  add_header_above(header = c("Naive Bayes" = 2, "Random Forest" = 2))
performance

## Performance on test set
naive_test_metrics <- final_metrics %>% dplyr::select(.metric, .estimate)
rnf_test_metrics <- rf_test_metrics %>% dplyr::select(.metric, .estimate)
test.metrics <- bind_cols(list(naive_test_metrics, rnf_test_metrics))
test.metrics <- as.data.frame(test.metrics)
rownames(test.metrics) <- c("Accuracy", "Jaccard's index", "Kappa", "AUC", "Sensitivity", "Specificity")
performance.test = kable(test.metrics, format = "latex", 
                         caption = "Model performance measures for Naive Bayes and random forest classification algorithms on the test dataset",
                      digits = 4, booktabs = TRUE, col.names = c("Metric", "Estimate", "Metric", "Estimate")) %>% 
  add_header_above(header = c("Naive Bayes" = 2, "Random Forest" = 2))
performance.test


##------------------------------------------------------------------------------
## Fit the best model on all the data with re-sampling
##------------------------------------------------------------------------------
## full data set is called sub_dfx

best_rf_model <- rand_forest(trees = 500, mtry = 2, min_n = 3) %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

rf_recipe <- recipe(Source2 ~ ., data = sub_dfx) %>% 
  step_upsample(Source2, over_ratio = 1) 

## re-sampling folds within the strata
foldsx <- vfold_cv(sub_dfx, v = 10, strata = Source2)

## build the workflow for the best model on all the data
rf_workflow <- 
  workflow() %>% 
  add_model(best_rf_model) %>% 
  add_recipe(rf_recipe)

rf_results <- fit_resamples(
  rf_workflow,
  resamples = foldsx,
  metrics = class_metrics
)

## collect the metrics on the trained random forest on all the folds 
best_rf_model_xtics <- collect_metrics(rf_results) %>% dplyr::select(.metric, mean, std_err)
best_rf_model_xtics

## create the table of performance measures based on re-sampling the data set for the best model [Table in paper]
final_best_model = kable(best_rf_model_xtics, format = "latex", 
                         caption = "Model performance measures for random forest classification on the full dataset with resampling",
                         digits = 4, booktabs = TRUE, col.names = c("Metric", "Estimate", "Standard error (SE)")) 
final_best_model



## THE MODEL
##------------------------------------------------------------------------------
## fit the model on the full training data set to make predictions on test set
final.rf.model <- workflow() %>% 
  add_model(best_rf_model) %>% 
  add_recipe(rf_recipe) %>% 
  fit(train)


## compute the final metrics for the random forest model [reported in supplimentary material]
rf.test.metrics <- predict(final.rf.model, sub_dfx, type = "prob") %>%
  bind_cols(predict(final.rf.model, sub_dfx)) %>%
  bind_cols(select(sub_dfx, Source2)) %>%
  class_metrics(Source2, .pred_dairy:.pred_vegetables, estimate = .pred_class)
rf.test.metrics


## gain and AUC curves [presented as supplementary materials]
## plot the AUC: first get predicted probabilities on the test set then use these for the plot for each potential food source
rf.probs <- predict(final.rf.model, sub_dfx, type = "prob") %>%
  bind_cols(sub_dfx) %>% 
  glimpse()


# Gain curve for each food source
rf_gain <- rf.probs %>%
  gain_curve(Source2, .pred_dairy:.pred_vegetables) %>%
  autoplot()
rf_gain


# ROC curve for each food source
rf_ROC <- rf.probs %>%
  roc_curve(Source2, .pred_dairy:.pred_vegetables) %>%
  autoplot()
rf_ROC


## save the naive gain curve to figures folder [Can include the AUC in paper?]
jpeg("figures\\rf_gain_full_best_model.jpeg", width = 4, height = 4, units = 'in', res = 300)
rf_gain
dev.off()

jpeg("figures\\rf_ROC_full_best_model.jpeg", width = 4, height = 4, units = 'in', res = 300)
rf_ROC
dev.off()


## save the model trained on the full data for use in food source attribution
saveRDS(final.rf.model, "data\\final.rf.model.rds")

## showing how to use model
##-----------------------------------------------------------------------------
## re-sample the data and show example of how model performs with 5 variables
idx <- c(1, 9, 14, 40, 53, 94, 193, 208, 173, 177)

## sample the rows to create the new data frame [can as supplimentary results]
newdf = sub_dfx[idx, ]

some_pred <- predict(final.rf.model, newdf, type = "prob") %>%
  bind_cols(newdf) %>%
  glimpse()

some_pred


