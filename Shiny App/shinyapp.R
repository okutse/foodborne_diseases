##load the required libraries
##------------------------------------------------------------------------------
library(data.table)
library(cowplot)
library(dplyr)
library(ggplot2)
library(shiny)
library(tidyverse)
library(ggthemes)
library(stringr)
library(reshape)
library(knitr)
#install.packages("bigrquery")
library(bigrquery)

## load the training data
##------------------------------------------------------------------------------
## read in raw file from our GitHub Repository
train <- fread("https://raw.githubusercontent.com/okutse/foodborne_diseases/main/data/train.csv", header = TRUE)



# Define UI for application----------------------------
ui <- fluidPage(
  
  # Application title
  titlePanel("Statistical Machine Learning for *Listeria monocytogene* Foodborne Disease Source Attribution"),
  
  navbarPage("Content",
             
            
             tabPanel("Prediction",
                      
                      # Sidebar with a slider input for number of bins 
                      sidebarLayout(
                        
                        # Sidebar panel for inputs
                        sidebarPanel(
                          
                          # Input: Set initial value for the model
                          selectInput(inputId = "Min.same",
                                      label = "Set Value of Min Same",
                                      choices = unique(sub_dfx$Min.same),
                                      selected = "0"),
                          selectInput(inputId = "Min.diff",
                                      label = "Set Value of Min Diff",
                                      choices = unique(sub_dfx$Min.diff),
                                      selected = "1"),
                          selectInput(inputId = "Strain",
                                      label = "Set Value of Strain",
                                      choices = as.list(levels(unique(sub_dfx$Strain))),
                                      selected = "CFSAN004372"),
                          selectInput(inputId = "Isolate",
                                      label = "Set Value of Isolate",
                                      choices = as.list(levels(unique(sub_dfx$Isolate))),
                                      selected = "PDT000000058.5"),
                          selectInput(inputId = "state",
                                      label = "Set Value of State",
                                      choices = as.list(levels(unique(sub_dfx$state))),
                                      selected = "WI"), 
                          selectInput(inputId = "SNP_Cluster",
                                      label = "Set Value of SNP Cluster",
                                      choices = as.list(levels(unique(sub_dfx$snp_cluster))),
                                      selected = "Others"),                           
                          selectInput(inputId = "season",
                                      label = "Set Value of Season",
                                      choices = as.list(levels(unique(sub_dfx$season))),
                                      selected = "Winter"),   
                          
                          submitButton(text = "Fit your model!")
                        ),
                        
                        mainPanel(
                          # show a table optimal parameter
                          tableOutput("optimalTable")
                          
                          
                        )
                      ),
             ),
             
             tabPanel("Reference",
                      
                      br(),
                      fluidRow(
                        column(8,
                               h4("Reference:"),
                               p("Our data is mainly webscraped from: ", 
                                 em(a("https://www.ncbi.nlm.nih.gov/pathogens/")),", ", 
                                 "All data usage complies with respective terms of use."
                               )),
                        column(4,
                               h4("Contact Us:"),
                               p("Amos Okutse: ",
                                 em(a("amos_okutse@brown.edu", href="mailto:amos_okutse@brown.edu"))),
                               p("Rophence Ojiambo: ",
                                 em(a("rophence_ojiambo@brown.edu", href="mailto:rophence_ojiambo@brown.edu"))),
                               p("Zexuan Yu: ",
                                 em(a("zexuan_yu@brown.edu", href="mailto:zexuan_yu@brown.edu"))),
                        )
                      )
                      
             )
  )
)

# Define server logic----------------------------
server <- function(input, output) {
  
  run_model <- reactive({
    train <- train <- fread("https://raw.githubusercontent.com/okutse/foodborne_diseases/main/data/train.csv", header = TRUE)
    sub_dfx<- fread("https://raw.githubusercontent.com/okutse/foodborne_diseases/main/data/final_df.csv", header = TRUE)

    
    #setting by users
    
    best_rf_model <- rand_forest(trees = 500, mtry = 2, min_n = 3) %>% 
      set_engine("ranger") %>% 
      set_mode("classification")
    
    rf_recipe <- recipe(Source2 ~ ., data = sub_dfx) %>% 
      step_upsample(Source2, over_ratio = 1) 
    final.rf.model <- workflow() %>% 
      add_model(best_rf_model) %>% 
      add_recipe(rf_recipe) %>% 
      fit(train)
    pred1<-predict(final.rf.model, input, type = "prob") %>%
      bind_cols(input) %>%
      glimpse()
    
    return(pred1)
    
  })
  

  
  output$optimalTable <- renderTable({
    
  
    
    
      #show the table of optimal parameter
    pred1 <- run_model()
    
    
    return(pred1)
    
  })
  
  
}

# Run the application----------------------------
shinyApp(ui = ui, server = server)