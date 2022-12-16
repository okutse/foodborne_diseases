
##load the required libraries
##------------------------------------------------------------------------------
library(data.table)
library(cowplot)
library(dplyr)
library(ggplot2)
library(shiny)
library(tidyverse)
library(DT)
library(ggthemes)
library(stringr)
library(reshape)
library(knitr)
library(bigrquery)
library(shinythemes)  ## use some other theme apart from the defaul e.g., flatly

## load the training data
##------------------------------------------------------------------------------
## read in raw file from our GitHub Repository
sub_dfx <- read.csv("final_df.csv", header = TRUE)


# Define UI for application----------------------------
ui <- fluidPage( theme = shinytheme("flatly"),
                 
                 # Application title
                 titlePanel(h1(HTML("<b>Machine Learning for <em>Listeria monocytogene</em> Pathogen Source Attribution</b>"), 
                               style = "text-align:center")),
                 
                 navbarPage(h3("Contents"), collapsible = TRUE,
                            
                            
                            tabPanel(h3("Prediction"),
                                     
                                     # Sidebar with a slider input for number of bins 
                                     sidebarLayout(
                                       
                                       # Sidebar panel for inputs
                                       sidebarPanel(
                                         
                                         # Input: Set initial value for the model
                                         selectInput(inputId = "Min.same",
                                                     label = "Set value of Min Same",
                                                     choices = unique(sub_dfx$Min.same),
                                                     selected = "0"),
                                         selectInput(inputId = "Min.diff",
                                                     label = "Set value of Min Diff",
                                                     choices = unique(sub_dfx$Min.diff),
                                                     selected = "1"),
                                         selectInput(inputId = "Strain",
                                                     label = "Set the strain type:",
                                                     choices = as.list(levels(unique(sub_dfx$Strain))),
                                                     selected = "CFSAN004372"),
                                         selectInput(inputId = "Isolate",
                                                     label = "Set the isolate type:",
                                                     choices = as.list(levels(unique(sub_dfx$Isolate))),
                                                     selected = "PDT000000058.5"),
                                         selectInput(inputId = "state",
                                                     label = "Set the location (state) the SNP was collected:",
                                                     choices = as.list(levels(unique(sub_dfx$state))),
                                                     selected = "WI"), 
                                         selectInput(inputId = "snp_cluster",
                                                     label = "Select the SNP Cluster:",
                                                     choices = as.list(levels(unique(sub_dfx$snp_cluster))),
                                                     selected = "Others"),                           
                                         selectInput(inputId = "season",
                                                     label = "Set the Season the strain was collected:",
                                                     choices = as.list(levels(unique(sub_dfx$season))),
                                                     selected = "Winter"),   
                                         
                                         actionButton("go", "Predict Isolation Source!")
                                       ),
                                       
                                       mainPanel(h3("Explore the pathogen's source attribution"),
                                                 fluidRow(p(h4(strong("Predicted Isolate Source")),
                                                            style = "color:black"),
                                                          ## show the table of predicted source in UI
                                                          DT::dataTableOutput("predictions_table")),
                                                 
                                                 ## show the probability associated with pathogen being from a particular source here
                                                 fluidRow(p(h4(strong("Source-specific Predicted Probabilities")),
                                                            style = "color:black"),
                                                          DT::dataTableOutput("predicted_probabilities"))#,
                                                 
                                                 
                                                 
                                       )
                                     )#,
                            ),
                            tabPanel(h3("Project Description"),
                                     mainPanel(
                                       ## Introduction
                                       p(h3(strong("Introduction and motivation:")), style = "color:blue"),
                                       p(h4(HTML("Listeria remains one of the most severe contributors to foodborne disease burden due to the severity of its clinical manifestations. 
                             The role of statistical models in linking pathogenic isolates of listeria to a particular source remains substantially unexplored in outbreak investigations.
                             In this project, we sought to develop a simple, yet robust statistical model to link <em>Listeria monocytogene</em> pathogens to a plausible isolation source. The project is informed by the fact that having a model that gives
                             the probability associated with a pathogen's isolation could be very useful in investigations of foodborne illnesses,
                             while also thinking about helping public health experts make informed decisions about what foods or sources of these
                             pathogens will result in the highest possible value when targeted by a public health policy. The predictive framework
                             also reduces the potential pool of isolation sources for further investigation by epidemiologists and biologists
                             using only easily available features in a lab and leverages genetic information."))),
                                       
                                       ## Data source
                                       p(h3(strong("Data source and variables:")), style = "color:blue"),
                                       p(h4(HTML("This project was created as part of a class project in Practical Data Analaysis under Dr. Alice Paul, and as part of a 
                             collaboration with Dr. Ernest Julian (Co-chair with the Centers for Disease Control and Prevention [CDC] and 
                             the Food and Drugs Administration [FDA] of the Healthy People 2030 Foodborne Illness Reduction Committee).
                             The project employed data downloaded from the <a href = https://www.ncbi.nlm.nih.gov/pathogens/><em>National Center for Biotechnology Information (NCBI)
                             Pathogens Detection Database.</em></a>"))),
                                       
                                       
                                       ## How it works/models
                                       p(h3(strong("How it works:")), style = "color:blue"),
                                       p(h4(HTML("The prediction algorithm is based on a random forest model trained using the minimum Single Nucleotide Polymorphism (SNP) distance to another of the 
                             same type, distance of a SNP to another of a different type, the strain of listeria, the isolate type, the state where the isolate was collected/sampled, the 
                             SNP cluster, and the season of sample collection. All variables were based on our explorations and scrapings of the features available on the NCBI pathogens detection
                             database. More detailed information about the specific modeling criteria can be found on the <a href = https://github.com/okutse/foodborne_diseases.><em>GitHub repository.</em></a>
                             
                             The model uses this features as inputs and spits out a plausible source of the isolate/pathogen. The main panel has been designed to give two tables: the 
                             first table is that of the predicted pathogens isolation source as well as the user inputs entered and the second is an exploration of the probabilities associated with each
                             of the ten potential pathogen sources examined in analysis including dairy, environment, fruits, human, leafy greens, meat, other unknown source, poultry,
                             sea food, and vegetables."))),
                                       
                                       ## concluding remarks
                                       p(h3(strong("Conclusions:")), style = "color:blue"),
                                       p(h4("While we acknowledge the potential limitations associated with our analysis, this model provides an avenue for disease outbreak investigators, food technologists, 
                             public health experts among other individuals to explore potential sources of food pathogens that might be of interest in further investigations, while thinking about the role
                             in resulting in reductions in the incidences of such diseases. The same framework can be extended to other foodborne disease pathogens and not just listeria outbreak investigations."))
                                       
                                     )),
                            
                            tabPanel(h3("About Us"),
                                     
                                     br(),
                                     fluidRow(
                                       column(8,
                                              h3("About Us"),
                                              p("Our data is mainly webscraped from: ", 
                                                em(a("https://www.ncbi.nlm.nih.gov/pathogens/")),", ", 
                                                "All data usage complies with respective terms of use."
                                              )),
                                       column(4,
                                              h3("Contact Us:"),
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
  
  ## load the saved best model object
  best_rf <- load("final.rf.model.rda")
  
  observeEvent(input$go, {
    output$predictions_table <- DT::renderDataTable({
      Min.same = as.integer(input$Min.same)
      Min.diff = as.integer(input$Min.diff)
      Strain = as.factor(input$Strain)
      Isolate = as.factor(input$Isolate)
      state = as.factor(input$state)
      snp_cluster = as.factor(input$snp_cluster)
      season = as.factor(input$season)
      
      ## create the data frame of user inputs from the UI
      new_df = data.frame(Min.same, Min.diff, Strain, Isolate, state, snp_cluster, season)
      new_df = data.frame(new_df)
      
      ## make predictions using the model and the saved model
      preds <- predict(final.rf.model, new_df, type = "class") %>% 
        bind_cols(new_df) 
      preds <- DT::datatable(preds, colnames = c("Predicted Pathogenic Source", "Min.same", "Min.diff", "Strain",
                                                 "Isolate", "State", "SNP cluster", "Season"))
      
    })
  })
  
  
  ## print out the predicted probabilities associated with each source
  observeEvent(input$go, {
    output$predicted_probabilities <- DT::renderDataTable({
      Min.same = as.integer(input$Min.same)
      Min.diff = as.integer(input$Min.diff)
      Strain = as.factor(input$Strain)
      Isolate = as.factor(input$Isolate)
      state = as.factor(input$state)
      snp_cluster = as.factor(input$snp_cluster)
      season = as.factor(input$season)
      
      ## create the data frame of user inputs from the UI
      new_df = data.frame(Min.same, Min.diff, Strain, Isolate, state, snp_cluster, season)
      new_df = data.frame(new_df)
      
      ## make predictions using the model and the saved model
      probs_df <- predict(final.rf.model, new_df, type = "prob") %>% 
        bind_cols(new_df)
      probs_df <- probs_df[, c(1:10)]
      probs_df<- probs_df %>% mutate_if(is.numeric, round, digits = 3)
      probs_df<- t(probs_df)
      probs_df <- DT::datatable(probs_df, rownames = c("Dairy", "Environment", "Fruits", 
                                                       "Humans", "Leafy greens", "Meat", "Other sources", "Poultry", 
                                                       "Sea food", "Vegetables"),
                                colnames = "Probability of the strain being from each isolation source")
      
    })
  })
  
  
  
}

# Run the application----------------------------
shinyApp(ui = ui, server = server)