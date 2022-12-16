## Statistical Machine Learning for *Listeria monocytogene* Food Source Attribution

This repository holds files related to the final project in PHP2550 Practical Data Analysis: *Statistical Machine Learning for Foodborne Disease Source Attribution* using *L. monocytogene* pathogen data downloaded from the [NCBI Pathogen Detection Database](https://www.ncbi.nlm.nih.gov/pathogens/) conducted in Fall 2022, School of Public Health, Brown University. This project sought to develop a statistical machine learning model for source attribution of *Listeria monocytogenes* pathogens to aid in foodborne illness source linkage in outbreak investigations. We made comparisons between 10-fold cross validated and minority class up-sampled Naive Bayes and random forest models. Given the robustness to class imbalance, high accuracy, and discriminatory ability, our results showed that the random forest model performed well in source attribution of listeria monocytogenes pathogens. More details on the results can be found in our [Final Report](https://github.com/okutse/foodborne_diseases/blob/main/Final%20Report/php2550_final_manuscript.pdf). Ultimately, we hope our model and results can be used to predict food sources attributable to *Listeria monocytogenes* outbreaks, and ultimately reduce foodborne disease incidence by proposing ways of enhancing food safety, and improve public health. 

------------------------------------------------------------

## Repository Organization 

- `Literature Review and Data Exploration`: This folder contains our written report of literature review and data exploration. Figures and references are also included. The code is hidden in the pdf version. 

- `Methods and Analysis Plan`: This folder contains our written Methods and Analysis Plan report done for this project, which showed our update beased on the first report of our literature review and data exploration. Figures and references are also included. The code is hidden in the pdf version. 

- `Poster`: This folder contains our Final Report Poster for this project. Figures used in this poster are also included.

- `Shiny App`:  This folder contains our shiny app for this project. Readers can use this shiny app to make their own predictions.

- `Supplementary Materials`: This folder contains our supplementary materials for this project. Pre-processing Steps, EDA, Methods, Modeling Part and Confusion Matrix Testing the Performance of Our Random Forest Model, as well as the code are included.

- `data`: This folder contains the `listeria_isolates.csv` data file used to conduct the analyses in our study. This is the cleaned data from the raw data files downloaded directly from the [NCBI website](https://www.ncbi.nlm.nih.gov/pathogens/). This folder also contains the `analysis_script.R`, which is the code used in the initial Exploratory Data Analysis (EDA), updated data pre-processing and brief use cases for sanity check. We also include the updated dataset used to conduct a brief use case in this folder. The training and the test set we divided are also contained.

- `figures`: This folder contains figures used in this project. Flow chart of the data cleaning process, trend plots in the poster, ROC and gain curves of our models are included.

- `Final Report`: This folder contains `php2550_final_manuscript.Rmd`, `php2550_final_manuscript.md` and `php2550_final_manuscript.pdf`files that constitute the final written final report for this project. The code is hidden in the pdf version. 

- `references.bib`: This file contains latest version of the references used in this project.


-------------------------------------------------------------
## Collaborators

[Amos Okutse](https://github.com/okutse)

[Rophence Ojiambo](https://github.com/rophenceojiambo)

[Zexuan Yu](https://github.com/ZXY57)

-------------------------------------------------------------
